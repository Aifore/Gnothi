import SwiftUI
import SwiftData

struct ResultView: View {
    @Bindable var record: TestRecord
    let test: PsychTest
    /// 刚测完时显示「完成」按钮；从历程进入时为 nil
    var onDone: (() -> Void)?

    @State private var appeared = false
    @State private var showExport = false

    var body: some View {
        let eval = test.evaluate(record)
        ScrollView {
            VStack(spacing: 20) {
                header(eval)

                if eval.showsCrisisSupport {
                    CrisisSupportCard()
                }

                if eval.dimensionScores.count > 1 {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("你的五个维度")
                            .font(.app(17, .semibold))
                            .foregroundStyle(Theme.ink)
                        RadarChart(labels: eval.dimensionScores.map { $0.dimension.name },
                                   values: eval.dimensionScores.map { $0.value / 100 },
                                   tint: test.tint)
                            .frame(height: 250)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .opacity(appeared ? 1 : 0)
                        DimensionBars(scores: eval.dimensionScores)
                    }
                    .card()
                } else if !test.bands.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("得分位置")
                            .font(.app(17, .semibold))
                            .foregroundStyle(Theme.ink)
                        BandGauge(score: record.total, maxScore: test.chartMax, bands: test.bands)
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("解读", systemImage: "text.quote")
                        .font(.app(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(eval.summary)
                        .font(.app(16))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .lineSpacing(5)
                }
                .card()

                if !eval.advice.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("可以试试", systemImage: "leaf")
                            .font(.app(17, .semibold))
                            .foregroundStyle(Theme.ink)
                        ForEach(eval.advice, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Sparkle().fill(test.tint).frame(width: 12, height: 12).padding(.top, 4)
                                Text(tip)
                                    .font(.app(15))
                                    .foregroundStyle(Theme.ink.opacity(0.85))
                            }
                        }
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("此刻的我", systemImage: "pencil.line")
                        .font(.app(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("写下现在的心情和最近发生的事。很久以后回看，它会让这个分数变得有温度。")
                        .font(.app(13))
                        .foregroundStyle(Theme.subInk)
                    TextField("最近的我……", text: $record.note, axis: .vertical)
                        .font(.app(16))
                        .lineLimit(3...10)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.background))
                }
                .card()

                Button { showExport = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.outline)
                            .frame(width: 42, height: 42)
                            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(test.tint.opacity(0.45)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("生成报告图片")
                                .font(.app(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("保存到相册，或分享给家人朋友")
                                .font(.app(12))
                                .foregroundStyle(Theme.subInk)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.subInk.opacity(0.6))
                    }
                    .card(padding: 14)
                }
                .buttonStyle(PressableStyle())

                Text(TestCatalog.disclaimer)
                    .font(.app(11))
                    .foregroundStyle(Theme.subInk.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                if let onDone {
                    Button("保存到我的历程") {
                        try? record.modelContext?.save()
                        onDone()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(20)
            .readableWidth(680)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showExport) {
            ReportExportView(record: record, test: test)
                .macSheetSize(width: 560, height: 820)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) { appeared = true }
        }
    }

    private func header(_ eval: Evaluation) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Blob(seed: 11, points: 8, variance: 0.14)
                    .fill(eval.color.opacity(0.3))
                    .frame(width: 190, height: 165)
                    .rotationEffect(.degrees(appeared ? 0 : -20))
                TestArt(kind: test.art)
                    .frame(width: 128, height: 128)
            }
            Text(test.title)
                .font(.app(15, .medium))
                .foregroundStyle(Theme.subInk)
            Text(eval.headline)
                .font(.app(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Chip(text: eval.scoreText, tint: eval.color)
            Text(Formatters.dayTime.string(from: record.date))
                .font(.app(12))
                .foregroundStyle(Theme.subInk)
        }
        .padding(.top, 8)
    }
}

// MARK: - Radar chart

struct RadarChart: View {
    let labels: [String]
    /// 0~1
    let values: [Double]
    var compare: [Double]? = nil
    var tint: Color
    var labelInset: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - labelInset
            ZStack {
                ForEach(1...4, id: \.self) { ring in
                    RadarPolygon(values: Array(repeating: Double(ring) / 4, count: labels.count), inset: labelInset)
                        .stroke(Theme.line, lineWidth: 1)
                }
                ForEach(labels.indices, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: RadarPolygon.point(index: i, count: labels.count, value: 1, center: center, radius: radius))
                    }
                    .stroke(Theme.line, lineWidth: 1)
                }
                if let compare {
                    RadarPolygon(values: compare, inset: labelInset)
                        .stroke(Theme.subInk, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
                RadarPolygon(values: values, inset: labelInset)
                    .fill(tint.opacity(0.35))
                RadarPolygon(values: values, inset: labelInset)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                ForEach(labels.indices, id: \.self) { i in
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                        .position(RadarPolygon.point(index: i, count: labels.count,
                                                     value: i < values.count ? values[i] : 0,
                                                     center: center, radius: radius))
                    Text(labels[i])
                        .font(.app(12, .semibold))
                        .foregroundStyle(Theme.subInk)
                        .fixedSize()
                        .position(RadarPolygon.point(index: i, count: labels.count, value: 1,
                                                     center: center, radius: radius + 20))
                }
            }
        }
    }
}

struct RadarPolygon: Shape {
    var values: [Double]
    var inset: CGFloat

    static func point(index: Int, count: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = -Double.pi / 2 + Double(index) / Double(max(count, 1)) * 2 * Double.pi
        let r = radius * CGFloat(min(max(value, 0), 1))
        return CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - inset
        var p = Path()
        for (i, v) in values.enumerated() {
            let pt = Self.point(index: i, count: values.count, value: v, center: center, radius: radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Dimension bars

struct DimensionBars: View {
    let scores: [DimensionScore]

    var body: some View {
        VStack(spacing: 18) {
            ForEach(scores) { item in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Circle().fill(item.dimension.color).frame(width: 9, height: 9)
                        Text(item.dimension.name)
                            .font(.app(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(Int(item.value.rounded()))%")
                            .font(.app(15, .bold))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.line)
                            Capsule()
                                .fill(item.dimension.color)
                                .frame(width: max(8, g.size.width * item.value / 100))
                        }
                    }
                    .frame(height: 8)
                    Text(item.note)
                        .font(.app(13))
                        .foregroundStyle(Theme.subInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Band gauge

struct BandGauge: View {
    let score: Double
    let maxScore: Double
    let bands: [Band]

    private func span(_ i: Int) -> Double {
        let lower = i == 0 ? -1 : bands[i - 1].upTo
        return Double(bands[i].upTo - lower)
    }

    var body: some View {
        let totalSpan = maxScore + 1
        GeometryReader { geo in
            let width = geo.size.width
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                    HStack(spacing: 3) {
                        ForEach(bands.indices, id: \.self) { i in
                            Capsule()
                                .fill(bands[i].color.opacity(0.85))
                                .frame(width: max(0, width * span(i) / totalSpan - 3), height: 12)
                        }
                    }
                    Circle()
                        .fill(Theme.card)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 3))
                        .frame(width: 22, height: 22)
                        .offset(x: min(max(0, width * (score + 0.5) / totalSpan - 11), width - 22))
                }
                .frame(height: 24)
                HStack(spacing: 3) {
                    ForEach(bands.indices, id: \.self) { i in
                        Text(bands[i].short)
                            .font(.app(11, .medium))
                            .foregroundStyle(Theme.subInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(width: max(0, width * span(i) / totalSpan - 3))
                    }
                }
            }
        }
        .frame(height: 48)
    }
}

// MARK: - Crisis support

struct Hotline: Identifiable {
    let name: String
    let number: String
    let tel: String
    var id: String { tel }

    static let all = [
        Hotline(name: "全国心理援助热线", number: "12356", tel: "12356"),
        Hotline(name: "希望24热线", number: "400-161-9995", tel: "4001619995"),
        Hotline(name: "北京心理危机干预中心", number: "010-82951332", tel: "01082951332"),
    ]
}

struct CrisisSupportCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.rose)
                Text("你不必独自面对")
                    .font(.app(18, .bold))
                    .foregroundStyle(Theme.ink)
            }
            Text("如果你正感到非常痛苦，或者有伤害自己的念头，请现在就联系专业人士或身边信任的人。他们愿意倾听，也能提供帮助。")
                .font(.app(14))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(4)
            ForEach(Hotline.all) { line in
                if let url = URL(string: "tel:\(line.tel)") {
                    Link(destination: url) {
                        HStack {
                            Text(line.name).font(.app(15, .medium))
                            Spacer()
                            Text(line.number).font(.app(15, .bold)).monospacedDigit()
                            Image(systemName: "phone.fill").font(.system(size: 13))
                        }
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.rose.opacity(0.22)))
                    }
                }
            }
            Text("遇到紧急危险，请立即拨打 110 或 120。")
                .font(.app(12))
                .foregroundStyle(Theme.subInk)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.rose.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .stroke(Theme.rose.opacity(0.5), lineWidth: 1.5)
        )
    }
}
