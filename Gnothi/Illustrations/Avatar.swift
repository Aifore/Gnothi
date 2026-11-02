import SwiftUI

/// 插画风头像：底色 + 发型
struct AvatarView: View {
    let colorIndex: Int
    let hairStyle: Int

    init(colorIndex: Int, hairStyle: Int) {
        self.colorIndex = colorIndex
        self.hairStyle = hairStyle
    }

    init(member: Member?) {
        self.colorIndex = member?.colorIndex ?? 0
        self.hairStyle = member?.hairStyle ?? 0
    }

    private var tint: Color { AvatarPalette.color(colorIndex) }

    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                Circle().fill(tint.opacity(0.4)).place(50, 50, 100, 100)
                if hairStyle == 2 {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.outline)
                        .place(50, 60, 54, 58)
                }
                Capsule().fill(tint).place(50, 104, 72, 50)
                Circle().fill(Theme.skin).place(50, 50, 42, 42)
                hair
                Circle().fill(Theme.outline).place(42, 53, 4.5, 4.5)
                Circle().fill(Theme.outline).place(58, 53, 4.5, 4.5)
                Capsule().fill(Theme.rose.opacity(0.6)).place(36, 60, 8, 5)
                Capsule().fill(Theme.rose.opacity(0.6)).place(64, 60, 8, 5)
                Arc(curve: 1)
                    .stroke(Theme.outline, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .place(50, 61, 10, 5)
            }
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var hair: some View {
        switch hairStyle {
        case 1: // 丸子头
            Circle().trim(from: 0.5, to: 1).fill(Theme.outline).place(50, 48, 46, 46)
            Circle().fill(Theme.outline).place(50, 22, 17, 17)
        case 2: // 长发
            Circle().trim(from: 0.5, to: 1).fill(Theme.outline).place(50, 48, 47, 47)
        case 3: // 毛线帽
            Circle().trim(from: 0.5, to: 1).fill(Theme.berry).place(50, 46, 48, 48)
            Capsule().fill(Theme.cloud).place(50, 45, 50, 9)
            Circle().fill(Theme.cloud).place(50, 21, 11, 11)
        default: // 短发
            Circle().trim(from: 0.5, to: 1).fill(Theme.outline).place(50, 47, 46, 46)
            Capsule().fill(Theme.outline).rotationEffect(.degrees(-25)).place(41, 33, 20, 8)
        }
    }
}
