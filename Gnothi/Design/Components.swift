import SwiftUI

// MARK: - Card

struct CardBackground: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
            )
    }
}

extension View {
    func card(padding: CGFloat = 20) -> some View {
        modifier(CardBackground(padding: padding))
    }

    /// 插画定位：在固定画布坐标系里放置元素（x, y 为中心点）
    func place(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        frame(width: w, height: h).position(x: x, y: y)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(17, .semibold))
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Capsule().fill(tint))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Small pieces

struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.app(20, .bold))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.app(13))
                    .foregroundStyle(Theme.subInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Chip: View {
    let text: String
    var tint: Color = Theme.sage
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 11, weight: .semibold))
            }
            Text(text).font(.app(12, .semibold))
        }
        .foregroundStyle(Theme.ink.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.28)))
    }
}

struct TagToggle: View {
    let text: String
    let selected: Bool
    var tint: Color = Theme.peach
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.app(14, .medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Capsule().fill(selected ? tint.opacity(0.35) : Theme.background))
                .overlay(Capsule().stroke(selected ? tint : Theme.line, lineWidth: 1.2))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}

struct ProgressCapsule: View {
    let progress: Double
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, geo.size.width * min(max(progress, 0), 1)))
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.app(24, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(.app(12))
                .foregroundStyle(Theme.subInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.2))
        )
    }
}
