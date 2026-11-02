import SwiftUI
import LocalAuthentication
import UserNotifications

// MARK: - Face ID / 密码锁

enum Biometrics {
    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

struct LockView: View {
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                SeedlingArt().frame(width: 170, height: 170)
                Text("Gnothi 已上锁")
                    .font(.app(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("你的心灵记录，只属于你")
                    .font(.app(15))
                    .foregroundStyle(Theme.subInk)
                Button {
                    Task { await unlock() }
                } label: {
                    Label("解锁", systemImage: "faceid")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
                .padding(.top, 12)
            }
        }
        .task { await unlock() }
    }

    @MainActor
    private func unlock() async {
        guard Biometrics.isAvailable else {
            onUnlock()
            return
        }
        if await Biometrics.authenticate(reason: "解锁查看你的心灵记录") {
            withAnimation(.easeOut(duration: 0.25)) { onUnlock() }
        }
    }
}

// MARK: - 每周提醒

enum Reminder {
    private static let identifier = "gnothi.weekly"

    /// 每周日晚上 8 点提醒
    static func enable() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Gnothi · 认识自己"
        content.body = "花三分钟，看看这一周的自己 🌱"
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        do {
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            return true
        } catch {
            return false
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
