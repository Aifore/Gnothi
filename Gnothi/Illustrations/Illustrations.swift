import SwiftUI

// MARK: - Canvas

/// 在固定坐标画布里作画，然后等比缩放到任意尺寸
struct ArtCanvas<Content: View>: View {
    let size: CGSize
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / size.width, geo.size.height / size.height)
            content()
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

enum ArtKind: String {
    case hero, personality, moodCloud, calmWave, puzzle, journey, seedling
}

/// 按类型返回插画
struct TestArt: View {
    let kind: ArtKind

    var body: some View {
        switch kind {
        case .hero: HeroArt()
        case .personality: PersonalityArt()
        case .moodCloud: MoodCloudArt()
        case .calmWave: CalmWaveArt()
        case .puzzle: PuzzleArt()
        case .journey: JourneyArt()
        case .seedling: SeedlingArt()
        }
    }
}

// MARK: - Building blocks

struct Cloud: View {
    var color: Color = Theme.cloud

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Capsule().fill(color).frame(width: w, height: h * 0.55).position(x: w / 2, y: h * 0.72)
                Circle().fill(color).frame(width: h * 0.8, height: h * 0.8).position(x: w * 0.38, y: h * 0.45)
                Circle().fill(color).frame(width: h * 0.6, height: h * 0.6).position(x: w * 0.64, y: h * 0.52)
            }
        }
    }
}

struct Sprout: View {
    var body: some View {
        ZStack {
            Capsule().fill(Theme.leaf).place(25, 46, 3.5, 48)
            Leaf().fill(Theme.leaf).rotationEffect(.degrees(-52)).place(14, 40, 16, 28)
            Leaf().fill(Theme.sage).rotationEffect(.degrees(48)).place(36, 30, 16, 28)
            Leaf().fill(Theme.leaf).rotationEffect(.degrees(-8)).place(24, 13, 14, 24)
        }
        .frame(width: 50, height: 70)
    }
}

/// 盘腿坐着、闭眼微笑的小人
struct PersonFigure: View {
    var shirt: Color = Theme.lavender
    var hair: Color = Theme.outline

    var body: some View {
        ZStack {
            Capsule().fill(Theme.sky).place(30, 84, 58, 14)
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(shirt).place(30, 62, 44, 44)
            Circle().fill(Theme.skin).place(30, 28, 32, 32)
            Circle().trim(from: 0.5, to: 1).fill(hair).place(30, 26.5, 35, 35)
            Circle().fill(hair).place(30, 7, 13, 13)
            Arc(curve: 1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).place(24, 31, 6, 3)
            Arc(curve: 1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).place(36, 31, 6, 3)
            Capsule().fill(Theme.rose.opacity(0.6)).place(20, 37, 6, 4)
            Capsule().fill(Theme.rose.opacity(0.6)).place(40, 37, 6, 4)
        }
        .frame(width: 60, height: 90)
    }
}

private func bird(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) -> some View {
    HStack(spacing: 0) {
        Arc(curve: -0.9).stroke(Theme.outline.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        Arc(curve: -0.9).stroke(Theme.outline.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }
    .place(x, y, s, s * 0.35)
}

// MARK: - Scenes

/// 首页主插画：山丘上闭眼静坐的人，太阳、云和嫩芽
struct HeroArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 340, height: 200)) {
            ZStack {
                Blob(seed: 4, points: 9, variance: 0.1).fill(Theme.peach.opacity(0.22)).place(170, 100, 330, 190)
                Circle().fill(Theme.butter.opacity(0.35)).place(262, 64, 94, 94)
                Circle().fill(Theme.butter).place(262, 64, 60, 60)
                Cloud().place(92, 52, 72, 32)
                Cloud().place(306, 116, 52, 24)
                bird(198, 46, 18)
                bird(220, 36, 12)
                Hill(peak: 0.7).fill(Theme.sage.opacity(0.55)).place(170, 160, 340, 80)
                Hill(peak: 0.2).fill(Theme.sage).place(170, 178, 340, 64)
                Sprout().place(64, 138, 46, 64)
                PersonFigure().place(168, 126, 60, 90)
                Sparkle().fill(Theme.lavender).place(118, 86, 14, 14)
                Sparkle().fill(Theme.rose).place(36, 80, 12, 12)
                Sparkle().fill(Theme.peach).place(306, 26, 10, 10)
            }
        }
    }
}

/// 大五人格：五瓣花，每一瓣代表一个维度
struct PersonalityArt: View {
    private let colors = [Theme.peach, Theme.rose, Theme.sage, Theme.sky, Theme.lavender]

    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(colors[i])
                        .frame(width: 38, height: 38)
                        .offset(y: -21)
                        .rotationEffect(.degrees(Double(i) * 72))
                        .position(x: 50, y: 52)
                }
                Circle().fill(Theme.cloud).place(50, 52, 30, 30)
                Circle().fill(Theme.outline).place(44.5, 50, 3.5, 3.5)
                Circle().fill(Theme.outline).place(55.5, 50, 3.5, 3.5)
                Arc(curve: 1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).place(50, 56, 9, 4)
            }
        }
    }
}

/// 情绪 / 抑郁量表：云后探出的太阳，下着小雨
struct MoodCloudArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                Circle().fill(Theme.butter).place(64, 36, 36, 36)
                Cloud().place(46, 52, 72, 36)
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(Theme.sky)
                        .rotationEffect(.degrees(18))
                        .place(30 + CGFloat(i) * 17, i == 1 ? 86 : 80, 5, 12)
                }
                Sparkle().fill(Theme.lavender).place(84, 70, 11, 11)
            }
        }
    }
}

/// 焦虑量表：月光下平静海面上的小帆船
struct CalmWaveArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                Circle().fill(Theme.butter).place(72, 26, 24, 24)
                Sparkle().fill(Theme.lavender).place(24, 24, 11, 11)
                Triangle().fill(Theme.peach).place(48, 44, 20, 26)
                Capsule().fill(Theme.rose).place(48, 60, 36, 9)
                Wave(amplitude: 0.3, cycles: 2)
                    .stroke(Theme.sky, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .place(50, 68, 84, 10)
                Wave(amplitude: 0.3, cycles: 2)
                    .stroke(Theme.sage, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .place(50, 80, 84, 10)
                Wave(amplitude: 0.3, cycles: 1.5)
                    .stroke(Theme.sky.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .place(50, 91, 64, 10)
            }
        }
    }
}

/// 认知 / 推理：几何积木
struct PuzzleArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.peach)
                    .rotationEffect(.degrees(14))
                    .place(33, 34, 30, 30)
                Triangle().fill(Theme.lavender).place(69, 34, 32, 30)
                Circle().fill(Theme.sky).place(33, 70, 30, 30)
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.butter).place(69, 70, 30, 30)
                Text("?")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.outline)
                    .position(x: 69, y: 70)
            }
        }
    }
}

/// 历程页：蜿蜒小路通往山顶的旗帜
struct JourneyArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 340, height: 170)) {
            ZStack {
                Blob(seed: 9, points: 9, variance: 0.1).fill(Theme.sky.opacity(0.18)).place(170, 88, 330, 168)
                Circle().fill(Theme.butter).place(296, 40, 34, 34)
                Cloud().place(70, 46, 54, 24)
                bird(118, 30, 16)
                bird(136, 22, 11)
                Mountain().fill(Theme.lavender.opacity(0.8)).place(232, 92, 190, 150)
                Mountain().fill(Theme.sky.opacity(0.85)).place(110, 114, 170, 106)
                Hill(peak: 0.35).fill(Theme.sage).place(170, 150, 340, 46)
                WindingPath()
                    .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: [2, 8]))
                    .place(178, 96, 150, 130)
                Capsule().fill(Theme.outline).place(241, 20, 2.5, 24)
                Triangle().fill(Theme.peach).rotationEffect(.degrees(90)).place(250, 14, 12, 14)
                Sparkle().fill(Theme.rose).place(30, 96, 11, 11)
                Sparkle().fill(Theme.butter).place(318, 104, 10, 10)
            }
        }
    }
}

/// 空状态 / 锁屏：笑眯眯的小盆栽
struct SeedlingArt: View {
    var body: some View {
        ArtCanvas(size: CGSize(width: 120, height: 120)) {
            ZStack {
                Blob(seed: 3, points: 8, variance: 0.12).fill(Theme.sage.opacity(0.25)).place(60, 62, 112, 104)
                Capsule().fill(Theme.outline.opacity(0.08)).place(60, 104, 56, 8)
                Capsule().fill(Theme.leaf).place(60, 52, 3.5, 32)
                Leaf().fill(Theme.leaf).rotationEffect(.degrees(-55)).place(48, 44, 16, 28)
                Leaf().fill(Theme.sage).rotationEffect(.degrees(55)).place(72, 40, 16, 28)
                Pot().fill(Theme.peach).place(60, 88, 46, 30)
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Theme.rose).place(60, 72, 54, 9)
                Circle().fill(Theme.outline).place(53, 87, 3.5, 3.5)
                Circle().fill(Theme.outline).place(67, 87, 3.5, 3.5)
                Arc(curve: 1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).place(60, 92, 8, 4)
                Sparkle().fill(Theme.butter).place(28, 30, 12, 12)
                Sparkle().fill(Theme.lavender).place(94, 26, 9, 9)
                Sparkle().fill(Theme.rose).place(98, 62, 7, 7)
            }
        }
    }
}

// MARK: - Mood face

enum MoodScale {
    static let labels = ["很糟", "低落", "平静", "不错", "超棒"]
    static let tags = ["工作", "学习", "家人", "朋友", "恋爱", "健康", "睡眠", "运动", "独处", "天气"]

    private static func clamp(_ m: Int) -> Int { min(max(m, 1), 5) }

    static func label(_ m: Int) -> String { labels[clamp(m) - 1] }

    static func color(_ m: Int) -> Color {
        [Theme.sky, Theme.lavender, Theme.sage, Theme.peach, Theme.butter][clamp(m) - 1]
    }

    static func curve(_ m: Int) -> CGFloat {
        [-0.9, -0.45, 0.1, 0.65, 1.0][clamp(m) - 1]
    }
}

/// 五档心情小脸，嘴角弧度会动画过渡
struct MoodFace: View {
    let mood: Int

    var body: some View {
        ArtCanvas(size: CGSize(width: 100, height: 100)) {
            ZStack {
                Blob(seed: 7, points: 8, variance: 0.07).fill(MoodScale.color(mood)).place(50, 50, 94, 94)
                Capsule().fill(Theme.rose.opacity(0.55)).place(27, 60, 13, 8)
                Capsule().fill(Theme.rose.opacity(0.55)).place(73, 60, 13, 8)
                if mood >= 5 {
                    Arc(curve: -1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 3.5, lineCap: .round)).place(36, 46, 12, 6)
                    Arc(curve: -1).stroke(Theme.outline, style: StrokeStyle(lineWidth: 3.5, lineCap: .round)).place(64, 46, 12, 6)
                } else {
                    Circle().fill(Theme.outline).place(36, 46, 8, mood == 1 ? 6 : 8)
                    Circle().fill(Theme.outline).place(64, 46, 8, mood == 1 ? 6 : 8)
                }
                Arc(curve: MoodScale.curve(mood))
                    .stroke(Theme.outline, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .place(50, 64, 28, 14)
            }
        }
    }
}

#Preview("Illustrations") {
    ScrollView {
        VStack(spacing: 24) {
            HeroArt().frame(height: 200)
            JourneyArt().frame(height: 170)
            HStack {
                PersonalityArt(); MoodCloudArt(); CalmWaveArt(); PuzzleArt()
            }
            .frame(height: 80)
            SeedlingArt().frame(height: 120)
            HStack { ForEach(1...5, id: \.self) { MoodFace(mood: $0) } }.frame(height: 60)
        }
        .padding()
    }
    .background(Theme.background)
}
