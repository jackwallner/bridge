import XCTest
@testable import Bridge

/// Answers every request with whatever the test last configured.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var statusCode = 201
    nonisolated(unsafe) static var fail = false
    nonisolated(unsafe) static var lastBody: Data?
    nonisolated(unsafe) static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        Self.lastBody = request.httpBody ?? request.httpBodyStream.map { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            return data
        }
        if Self.fail {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
final class FeedbackServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var service: FeedbackService!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "FeedbackServiceTests")!
        defaults.removePersistentDomain(forName: "FeedbackServiceTests")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.statusCode = 201
        StubURLProtocol.fail = false
        StubURLProtocol.lastBody = nil
        StubURLProtocol.requestCount = 0
        service = FeedbackService(
            endpoint: FeedbackEndpoint(url: URL(string: "https://stub.invalid/rest/v1/app_feedback")!, apiKey: "test"),
            defaults: defaults,
            session: URLSession(configuration: config)
        )
    }

    func testPayloadUsesTheTableColumns() throws {
        let submission = FeedbackService.makeSubmission(
            kind: .question,
            message: "The answer seems wrong",
            context: ["item_id": "q-1"],
            isMember: true
        )
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(submission)) as? [String: Any])
        XCTAssertEqual(json["app"] as? String, "bridge")
        XCTAssertEqual(json["kind"] as? String, "question")
        XCTAssertEqual(json["is_member"] as? Bool, true)
        XCTAssertNotNil(json["app_version"])
        XCTAssertNotNil(json["os_version"])
        XCTAssertEqual((json["context"] as? [String: String])?["item_id"], "q-1")
        XCTAssertNil(json["isMember"], "camelCase keys would be rejected by the table")
    }

    func testAcceptedSubmissionIsSentAndNotQueued() async {
        let outcome = await service.submit(kind: .general, message: "Love it", isMember: false)
        XCTAssertEqual(outcome, .sent)
        XCTAssertEqual(service.pendingCount, 0)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
    }

    func testUnreachableServerQueuesAndFlushRetries() async {
        StubURLProtocol.fail = true
        let outcome = await service.submit(kind: .churn, message: "[Too expensive]", isMember: false)
        XCTAssertEqual(outcome, .queued)
        XCTAssertEqual(service.pendingCount, 1)

        StubURLProtocol.fail = false
        await service.flushPending()
        XCTAssertEqual(service.pendingCount, 0)
        XCTAssertEqual(StubURLProtocol.requestCount, 2)
    }

    func testOfflineRetryKeepsEveryQueuedReport() async {
        StubURLProtocol.fail = true
        for i in 0..<3 {
            _ = await service.submit(kind: .question, message: "report \(i)", isMember: false)
        }
        XCTAssertEqual(service.pendingCount, 3)

        await service.flushPending()
        XCTAssertEqual(service.pendingCount, 3, "a retry that is still offline must not lose reports")

        StubURLProtocol.fail = false
        await service.flushPending()
        XCTAssertEqual(service.pendingCount, 0)
    }

    func testFlushDropsRefusedRowsAndKeepsGoing() async {
        StubURLProtocol.fail = true
        _ = await service.submit(kind: .general, message: "a", isMember: false)
        _ = await service.submit(kind: .general, message: "b", isMember: false)
        StubURLProtocol.fail = false
        StubURLProtocol.statusCode = 400
        await service.flushPending()
        XCTAssertEqual(service.pendingCount, 0)
    }

    func testRejectedSubmissionIsDroppedNotQueued() async {
        StubURLProtocol.statusCode = 401
        let outcome = await service.submit(kind: .general, message: "x", isMember: false)
        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(service.pendingCount, 0, "a row the server refused must not be retried forever")
    }

    func testBlankMessageNeverSends() async {
        let outcome = await service.submit(kind: .general, message: "   \n", isMember: false)
        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    func testQueueIsCapped() async {
        StubURLProtocol.fail = true
        for i in 0..<25 {
            _ = await service.submit(kind: .general, message: "m\(i)", isMember: false)
        }
        XCTAssertEqual(service.pendingCount, 20)
    }
}
