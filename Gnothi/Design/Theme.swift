import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }

    /// 浅色 / 深色模式自动切换的颜色
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        func component(_ hex: UInt32, _ shift: UInt32) -> CGFloat { CGFloat((hex >> shift) & 0xFF) / 255 }
        #if canImport(UIKit)
        return Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: component(hex, 16), green: component(hex, 8), blue: component(hex, 0), alpha: 1)
        })
        #else
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? dark : light
            return NSColor(srgbRed: component(hex, 16), green: component(hex, 8), blue: component(hex, 0), alpha: 1)
        })
        #endif
    }
}

// MARK: - Theme

enum Theme {
    // 界面色
    static let background = Color.dynamic(light: 0xFBF7F1, dark: 0x17161C)
    static let card = Color.dynamic(light: 0xFFFFFF, dark: 0x24222B)
    static let ink = Color.dynamic(light: 0x2E2A3B, dark: 0xF2EEE6)
    static let subInk = Color.dynamic(light: 0x8A8496, dark: 0xA7A1B2)
    static let line = Color.dynamic(light: 0xEDE6DB, dark: 0x34313C)

    // 插画色板（柔和马卡龙）
    static let peach = Color(hex: 0xF4A88C)
    static let sage = Color(hex: 0x9CC5A1)
    static let leaf = Color(hex: 0x6FA77A)
    static let lavender = Color(hex: 0xB8A9E3)
    static let sky = Color(hex: 0x8EC5E8)
    static let butter = Color(hex: 0xF6D47A)
    static let rose = Color(hex: 0xEE9AA8)
    static let berry = Color(hex: 0xE07A8A)
    static let skin = Color(hex: 0xF7D2B8)
    static let cloud = Color(hex: 0xFFFFFF)
    /// 插画细节线条（固定深色，画在彩色块上）
    static let outline = Color(hex: 0x2E2A3B)

    static let corner: CGFloat = 24
}

extension Font {
    /// 全局使用圆体，柔和亲切
    static func app(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Formatters

enum Formatters {
    private static let locale = Locale(identifier: "zh_Hans_CN")

    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = format
        return f
    }

    static let month = make("yyyy年M月")
    static let day = make("M月d日")
    static let dayTime = make("M月d日 HH:mm")
    static let time = make("HH:mm")
    static let weekday = make("M月d日 EEEE")
    static let shortDate = make("yyyy.M.d")

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = locale
        f.unitsStyle = .full
        return f
    }()

    static func relativeString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "今天" }
        if Calendar.current.isDateInYesterday(date) { return "昨天" }
        return relative.localizedString(for: date, relativeTo: .now)
    }

    static func greeting(_ date: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 0..<5: return "夜深了"
        case 5..<11: return "早上好"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }
}
