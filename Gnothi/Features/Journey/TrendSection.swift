import SwiftUI
import Charts

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let series: String
}

struct TrendSection: View {
    let records: [TestRecord]
    let moods: [MoodEntry]
    @State private var selectedID: String?

    private var availableTests: [PsychTest] {
        TestCatalog.all.filter { test in records.contains { $0.testID == test.id } }
    }

    private var currentTest: PsychTest? {
        availableTests.first { $0.id == selectedID } ?? availableTests.first
    }

    var body: some View {
        VStack(spacing: 20) {
            if !moods.isEmpty {
                MoodTrendCard(moods: moods)
            }

            if let test = currentTest {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableTests) { t in
                            Button {
                                withAnimation(.easeInOut) { selectedID = t.id }
                            } label: {
                                Text(t.title)
                                    .font(.app(14, .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(Capsule().fill(t.id == test.id ? t.tint.opacity(0.4) : Theme.card))
                                    .overlay(Capsule().stroke(t.id == test.id ? t.tint : Theme.line, lineWidth: 1.2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                let history = records.filter { $0.testID == test.id }.sorted { $0.date < $1.date }
                TestTrendCard(test: test, history: history)

                if test.dimensions.count > 1, history.count >= 2,
                   let first = history.first, let latest = history.last {
                    CompareCard(test: test, first: first, latest: latest)
                }
            } else {
                Text("完成测试后，这里会出现你的变化曲线")
                    .font(.app(14))
                    .foregroundStyle(Theme.subInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Test trend

struct TestTrendCard: View {
    let test: PsychTest
    let history: [TestRecord]

    private var points: [ChartPoint] {
        history.flatMap { record in
            test.dimensions.indices.compactMap { i -> ChartPoint? in
                guard i < record.scores.count else { return nil }
                return ChartPoint(date: record.date, value: record.scores[i], series: test.dimensions[i].name)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(test.title) · 变化曲线")
                    .font(.app(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("共 \(history.count) 次")
                    .font(.app(12, .medium))
                    .foregroundStyle(Theme.subInk)
            }

            Chart {
                // 分级分界线（例如 PHQ-9 的 5 / 10 / 15 / 20 分）
                ForEach(test.bands.dropLast().indices, id: \.self) { i in
                    RuleMark(y: .value("分界", Double(test.bands[i].upTo) + 0.5))
                        .foregroundStyle(test.bands[i + 1].color.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                }
                ForEach(points) { p in
                    LineMark(x: .value("日期", p.date), y: .value("分数", p.value))
                        .foregroundStyle(by: .value("维度", p.series))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    PointMark(x: .value("日期", p.date), y: .value("分数", p.value))
                        .foregroundStyle(by: .value("维度", p.series))
                        .symbolSize(40)
                }
            }
            .chartForegroundStyleScale(domain: test.dimensions.map(\.name),
                                       range: test.dimensions.map(\.color))
            .chartYScale(domain: 0...test.chartMax)
            .chartLegend(test.dimensions.count > 1 ? .visible : .hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                }
            }
            .frame(height: 220)

            if history.count < 2 {
                Label("再测一次，就能看到自己的变化啦", systemImage: "sparkles")
                    .font(.app(13))
                    .foregroundStyle(Theme.subInk)
            } else if let first = history.first, let last = history.last, test.dimensions.count == 1 {
                let delta = last.total - first.total
                Text(changeText(delta: delta, first: first))
                    .font(.app(14))
                    .foregroundStyle(Theme.ink.opacity(0.8))
            }
        }
        .card()
    }

    private func changeText(delta: Double, first: TestRecord) -> String {
        let since = Formatters.shortDate.string(from: first.date)
        if abs(delta) < 1 { return "和 \(since) 第一次测试相比，基本持平。" }
        let n = Int(abs(delta).rounded())
        // 情绪量表分数越低越好，推理题分数越高越好
        let higherIsBetter = test.category == .cognition
        let better = (delta > 0) == higherIsBetter
        return "和 \(since) 第一次测试相比，\(delta > 0 ? "上升" : "下降")了 \(n) 分\(better ? "，状态在变好 🌱" : "，记得多照顾自己。")"
    }
}

// MARK: - Compare (first vs latest)

struct CompareCard: View {
    let test: PsychTest
    let first: TestRecord
    let latest: TestRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("那时的我 vs 现在的我")
                .font(.app(17, .semibold))
                .foregroundStyle(Theme.ink)

            RadarChart(labels: test.dimensions.map(\.name),
                       values: latest.scores.map { $0 / 100 },
                       compare: first.scores.map { $0 / 100 },
                       tint: test.tint)
                .frame(height: 230)

            HStack(spacing: 16) {
                legend(dashed: true, text: "首次 \(Formatters.shortDate.string(from: first.date))")
                legend(dashed: false, text: "最近 \(Formatters.shortDate.string(from: latest.date))")
            }

            VStack(spacing: 10) {
                ForEach(test.dimensions.indices, id: \.self) { i in
                    if i < first.scores.count, i < latest.scores.count {
                        let delta = latest.scores[i] - first.scores[i]
                        HStack {
                            Circle().fill(test.dimensions[i].color).frame(width: 8, height: 8)
                            Text(test.dimensions[i].name)
                                .font(.app(14, .medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(deltaText(delta))
                                .font(.app(14, .bold))
                                .monospacedDigit()
                                .foregroundStyle(abs(delta) < 3 ? Theme.subInk : Theme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(test.dimensions[i].color.opacity(abs(delta) < 3 ? 0.1 : 0.3)))
                        }
                    }
                }
            }
        }
        .card()
    }

    private func deltaText(_ d: Double) -> String {
        let n = Int(d.rounded())
        if n == 0 { return "持平" }
        return n > 0 ? "+\(n)" : "\(n)"
    }

    private func legend(dashed: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .stroke(dashed ? Theme.subInk : test.tint,
                        style: StrokeStyle(lineWidth: 2, dash: dashed ? [3, 3] : []))
                .frame(width: 18, height: 2)
            Text(text)
                .font(.app(12))
                .foregroundStyle(Theme.subInk)
        }
    }
}

// MARK: - Mood trend

struct MoodTrendCard: View {
    let moods: [MoodEntry]

    private var dailyPoints: [ChartPoint] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: .now)) else { return [] }
        let recent = moods.filter { $0.date >= start }
        let grouped = Dictionary(grouping: recent) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { day, entries in
                ChartPoint(date: day,
                           value: Double(entries.map(\.mood).reduce(0, +)) / Double(entries.count),
                           series: "心情")
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        let points = dailyPoints
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("近 30 天心情")
                    .font(.app(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if !points.isEmpty {
                    let avg = points.map(\.value).reduce(0, +) / Double(points.count)
                    HStack(spacing: 6) {
                        MoodFace(mood: Int(avg.rounded())).frame(width: 22, height: 22)
                        Text("平均 \(MoodScale.label(Int(avg.rounded())))")
                            .font(.app(12, .medium))
                            .foregroundStyle(Theme.subInk)
                    }
                }
            }

            if points.isEmpty {
                Text("最近 30 天还没有心情记录")
                    .font(.app(13))
                    .foregroundStyle(Theme.subInk)
            } else {
                Chart(points) { p in
                    AreaMark(x: .value("日期", p.date, unit: .day),
                             yStart: .value("基线", 0.5),
                             yEnd: .value("心情", p.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.peach.opacity(0.35), Theme.peach.opacity(0.02)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                    LineMark(x: .value("日期", p.date, unit: .day), y: .value("心情", p.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.peach)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    PointMark(x: .value("日期", p.date, unit: .day), y: .value("心情", p.value))
                        .foregroundStyle(MoodScale.color(Int(p.value.rounded())))
                        .symbolSize(36)
                }
                .chartYScale(domain: 0.5...5.5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1.0, 3.0, 5.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(MoodScale.label(Int(v)))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                    }
                }
                .frame(height: 170)
            }
        }
        .card()
    }
}
