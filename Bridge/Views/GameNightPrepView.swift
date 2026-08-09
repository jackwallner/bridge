import SwiftUI
import UIKit

struct GameNightPrepView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var records = PracticeRecordStore.shared

    private var sessionItems: [QuickItem] {
        SessionBuilder.gameNightPrep(
            seen: progress.seenItems,
            missed: progress.missedItems,
            dueIDs: records.reviewQueue(),
            weakestRoomID: records.weakestRoom()?.id
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                scheduleCard
                personalizedCard
                NavigationLink {
                    QuickSessionView(gameNightPrep: sessionItems)
                } label: {
                    Text("Start My Five-Minute Prep").primaryCTA(color: Theme.plum)
                }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Game Night Prep")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications are off", isPresented: $settings.reminderPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Bridge Trainer cannot send reminders until notifications are turned on in iOS Settings.")
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.plum)
                .frame(width: 68, height: 68)
                .background(Theme.plum.opacity(0.13), in: Circle())
            Text("Walk in ready")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
            Text("Set your usual bridge night. The reminder opens a fresh session built from your mistakes, weakest room, and material you have not seen yet.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY REMINDER")
                        .font(.caption.weight(.heavy))
                        .kerning(1.4)
                        .foregroundStyle(Theme.inkSecondary)
                    Text(settings.gameNightReminderEnabled ? "Prep is scheduled" : "Choose your game night")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                Toggle("Weekly game night reminder", isOn: $settings.gameNightReminderEnabled)
                    .labelsHidden()
            }
            Divider().overlay(Theme.rule)
            Picker("Game Night", selection: $settings.gameNightDay) {
                ForEach(AppSettings.GameNightDay.allCases) { day in
                    Text(day.displayName).tag(day)
                }
            }
            DatePicker(
                "Prep Reminder",
                selection: $settings.gameNightReminderTime,
                displayedComponents: .hourAndMinute
            )
            Text("At that time each \(settings.gameNightDay.displayName), the notification opens directly into your personalized practice session.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private var personalizedCard: some View {
        let weakest = records.weakestRoom()
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 40, height: 40)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("What today's prep targets")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(personalizationCopy(weakest))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func personalizationCopy(_ weakest: PracticeRecordStore.RoomStat?) -> String {
        if records.dueCount > 0, let weakest {
            return "\(records.dueCount) due mistake\(records.dueCount == 1 ? "" : "s") first, then extra work in \(weakest.name)."
        }
        if records.dueCount > 0 {
            return "\(records.dueCount) due mistake\(records.dueCount == 1 ? "" : "s") first, followed by material you have not seen yet."
        }
        if let weakest {
            return "Extra work in \(weakest.name), followed by a balanced mix from the other rooms."
        }
        return "A balanced member mix now. As you answer more questions, this session will zero in on your real weak spots."
    }
}
