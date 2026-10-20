import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Why a piece of feedback was written. Stored as the `kind` column so the
/// inbox can be sorted by moment rather than read as one pile.
enum FeedbackKind: String, Codable, Sendable {
    /// Settings > Send Feedback.
    case general
    /// The retired enjoyment funnel's "not really" branch. Nothing sends it
    /// now; kept because the table still accepts it.
    case notEnjoying = "not_enjoying"
    /// The per-question report link, removed before 1.4.1 shipped. Nothing
    /// sends it now; kept so reports queued on a TestFlight build still decode.
    case question
    /// The one question asked when a trial or membership is on its way out.
    case churn
}

/// One submission, exactly as it goes over the wire. Nothing here identifies
/// the player: no account exists, and the context is counts, ids and short
/// labels only.
struct FeedbackSubmission: Codable, Equatable, Sendable {
    let app: String
    let kind: FeedbackKind
    let message: String
    let context: [String: String]
    let appVersion: String
    let osVersion: String
    let device: String
    let locale: String
    let isMember: Bool

    enum CodingKeys: String, CodingKey {
        case app, kind, message, context, device, locale
        case appVersion = "app_version"
        case osVersion = "os_version"
        case isMember = "is_member"
    }
}

/// Where feedback lands: a single insert-only table behind a publishable key.
/// The key can only insert rows for this app, never read them, so shipping it
/// in the binary gives away nothing.
struct FeedbackEndpoint: Sendable {
    let url: URL
    let apiKey: String

    static let production = FeedbackEndpoint(
        url: URL(string: "https://ucoveqbyfuxqvpysmixu.supabase.co/rest/v1/app_feedback")!,
        apiKey: "sb_publishable_8wdV5K70eGYcx8rWtD6DEg_OnP33dHr"
    )
}

/// Sends feedback straight from the app instead of drafting an email.
///
/// The mail draft was where feedback died: it needed a configured Mail app,
/// an app switch, and a second Send, and a long tail of players never set
/// Mail up at all. A text field and one button is the whole bar now.
///
/// Delivery is best-effort with a queue: a submission that cannot reach the
/// server (offline, server down) is kept locally and retried on the next
/// launch. A submission the server REJECTS (a 4xx) is dropped, because
/// retrying a rejected row forever is a bug, not persistence.
@MainActor
final class FeedbackService: ObservableObject {
    static let shared = FeedbackService()

    enum Outcome: Equatable, Sendable {
        /// The server accepted it.
        case sent
        /// Could not reach the server; saved for the next launch.
        case queued
        /// The server refused it. Nothing more will be tried.
        case failed
    }

    static let appID = "bridge"
    private static let pendingKey = "feedback.pending"
    /// A queue that grows without bound on a device that is never online is
    /// just a leak with a nicer name.
    private static let maxPending = 20

    private let endpoint: FeedbackEndpoint
    private let defaults: UserDefaults
    private let session: URLSession
    private var isFlushing = false

    init(
        endpoint: FeedbackEndpoint = .production,
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.defaults = defaults
        self.session = session
    }

    // MARK: - Submitting

    func submit(
        kind: FeedbackKind,
        message: String,
        context: [String: String] = [:],
        isMember: Bool
    ) async -> Outcome {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failed }
        let submission = Self.makeSubmission(
            kind: kind,
            message: String(trimmed.prefix(4000)),
            context: context,
            isMember: isMember
        )
        return await deliver(submission)
    }

    /// Retries anything a previous launch could not send. Cheap when the
    /// queue is empty, which is nearly always.
    ///
    /// Each row leaves the stored queue only once the server has answered for
    /// it, so a retry that is still offline keeps every report, and a report
    /// queued while a flush is suspended is never overwritten.
    func flushPending() async {
        guard !isFlushing else { return }
        isFlushing = true
        defer { isFlushing = false }
        // One pass over what was queued when the flush began. A row the
        // server keeps failing (5xx) stays queued but does not block the rows
        // behind it; the cap ages it out eventually.
        for next in pending {
            do {
                // Accepted or refused, the server has answered: either way the
                // row is done.
                _ = try await post(next)
            } catch let error as URLError where error.code == .badServerResponse {
                continue
            } catch {
                return // Unreachable: try everything again next launch.
            }
            var queue = pending
            if let index = queue.firstIndex(of: next) {
                queue.remove(at: index)
            }
            pending = queue
        }
    }

    var pendingCount: Int { pending.count }

    // MARK: - Internals

    static func makeSubmission(
        kind: FeedbackKind,
        message: String,
        context: [String: String],
        isMember: Bool,
        bundle: Bundle = .main
    ) -> FeedbackSubmission {
        var fullContext = context
        #if DEBUG
        fullContext["build"] = "debug"
        #endif
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return FeedbackSubmission(
            app: appID,
            kind: kind,
            message: message,
            context: fullContext,
            appVersion: "\(version) (\(build))",
            osVersion: osVersion,
            device: deviceModel,
            locale: Locale.current.identifier,
            isMember: isMember
        )
    }

    private func deliver(_ submission: FeedbackSubmission) async -> Outcome {
        do {
            let accepted = try await post(submission)
            if accepted { return .sent }
            return .failed
        } catch {
            enqueue(submission)
            return .queued
        }
    }

    /// True when the server took the row, false when it refused it. Throws
    /// only when the server could not be reached at all.
    private func post(_ submission: FeedbackSubmission) async throws -> Bool {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(endpoint.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(endpoint.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(submission)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch http.statusCode {
        case 200..<300: return true
        // Timeouts and rate limits pass; keep the row and retry later.
        case 408, 429, 500..<600: throw URLError(.badServerResponse)
        default: return false
        }
    }

    private var pending: [FeedbackSubmission] {
        get {
            guard let data = defaults.data(forKey: Self.pendingKey),
                  let decoded = try? JSONDecoder().decode([FeedbackSubmission].self, from: data) else { return [] }
            return decoded
        }
        set {
            if newValue.isEmpty {
                defaults.removeObject(forKey: Self.pendingKey)
            } else if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Self.pendingKey)
            }
        }
    }

    private func enqueue(_ submission: FeedbackSubmission) {
        var queue = pending
        queue.append(submission)
        if queue.count > Self.maxPending {
            queue.removeFirst(queue.count - Self.maxPending)
        }
        pending = queue
    }

    private static var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    private static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "unknown" : identifier
    }
}
