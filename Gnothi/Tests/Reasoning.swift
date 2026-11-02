import SwiftUI

/// 数字推理：题目由程序随机生成（原创题型，无版权问题）。
/// 注意：这是思维练习，不是标准化智商测验。
extension TestCatalog {
    static let reasoningCount = 12

    static let reasoning: PsychTest = {
        let bands = [
            Band(upTo: 4, label: "热身中", short: "热身", color: Theme.sky,
                 summary: "大脑还在热身。找规律是可以练出来的，多做几次，你会明显感觉到变快。"),
            Band(upTo: 8, label: "思路稳健", short: "稳健", color: Theme.sage,
                 summary: "你能发现大部分常见规律，思路清晰稳健。"),
            Band(upTo: 10, label: "思维敏锐", short: "敏锐", color: Theme.butter,
                 summary: "你对数字规律很敏感，复杂一些的变化也难不倒你。"),
            Band(upTo: 12, label: "推理高手", short: "高手", color: Theme.peach,
                 summary: "几乎全对！你的模式识别能力非常出色。"),
        ]
        return PsychTest(
            id: "reasoning",
            title: "数字推理",
            subtitle: "找规律 · 思维敏捷度练习",
            category: .cognition,
            art: .puzzle,
            tint: Theme.butter,
            minutes: 5,
            intro: "观察一串数字，找出其中的规律，选出下一个数。题目从易到难，每次都随机生成。\n\n这是思维练习，不是标准化的智商测验。定期练习，看看自己的变化。",
            prompt: nil,
            kind: .reasoning(count: TestCatalog.reasoningCount),
            dimensions: [Dimension(name: "答对题数", color: Theme.butter)],
            bands: bands,
            chartMax: Double(TestCatalog.reasoningCount),
            retestDays: 7,
            source: "题目由 Gnothi 随机生成",
            score: { answers in
                let correct = Double(answers.reduce(0, +))
                return ([correct], correct)
            },
            evaluate: { record in
                let band = bands.first { Int(record.total) <= $0.upTo } ?? bands[bands.count - 1]
                let count = max(record.answers.count, 1)
                let perQuestion = record.duration / Double(count)
                return Evaluation(
                    headline: band.label,
                    scoreText: "答对 \(Int(record.total)) / \(count) · 平均每题 \(String(format: "%.1f", perQuestion)) 秒",
                    summary: band.summary,
                    color: band.color
                )
            }
        )
    }()
}

// MARK: - Question generator

struct SeriesQuestion: Identifiable {
    let id = UUID()
    let shown: [Int]
    let answer: Int
    let options: [Int]
    let rule: String
}

enum SeriesGenerator {
    static func makeSet(count: Int = TestCatalog.reasoningCount) -> [SeriesQuestion] {
        (0..<count).map { i in make(level: i * 4 / max(count, 1)) }
    }

    /// level 0~3，越大越难
    static func make(level: Int) -> SeriesQuestion {
        let kinds: [Int]
        switch level {
        case 0: kinds = [0, 1]
        case 1: kinds = [0, 1, 2]
        case 2: kinds = [2, 3, 4]
        default: kinds = [3, 4, 5, 6]
        }

        var seq: [Int] = []
        var rule = ""
        switch kinds.randomElement() ?? 0 {
        case 0:
            let a = Int.random(in: 1...20), d = Int.random(in: 2...9)
            seq = (0..<6).map { a + d * $0 }
            rule = "每次加 \(d)"
        case 1:
            let a = Int.random(in: 1...4), r = Int.random(in: 2...3)
            seq = (0..<6).map { a * Int(pow(Double(r), Double($0))) }
            rule = "每次乘 \(r)"
        case 2:
            let k = Int.random(in: 1...3)
            var x = Int.random(in: 1...10)
            var step = Int.random(in: 1...4)
            seq = [x]
            for _ in 1..<6 { x += step; step += k; seq.append(x) }
            rule = "相邻差依次增加 \(k)"
        case 3:
            let a = Int.random(in: 1...10), d1 = Int.random(in: 2...5)
            let b = Int.random(in: 30...45), d2 = Int.random(in: 1...4)
            seq = (0..<6).map { $0 % 2 == 0 ? a + d1 * ($0 / 2) : b - d2 * ($0 / 2) }
            rule = "奇数位和偶数位各成一列"
        case 4:
            var x0 = Int.random(in: 1...5), x1 = Int.random(in: 2...7)
            seq = [x0, x1]
            for _ in 2..<6 { let next = x0 + x1; seq.append(next); x0 = x1; x1 = next }
            rule = "每一项等于前两项之和"
        case 5:
            let n = Int.random(in: 1...4), c = Int.random(in: 0...5)
            seq = (0..<6).map { (n + $0) * (n + $0) + c }
            rule = c == 0 ? "连续的平方数" : "平方数再加 \(c)"
        default:
            let c = Int.random(in: 1...3)
            var x = Int.random(in: 1...3)
            seq = [x]
            for _ in 1..<6 { x = x * 2 + c; seq.append(x) }
            rule = "乘 2 再加 \(c)"
        }

        let shown = Array(seq.prefix(5))
        let answer = seq[5]
        let diff = seq[5] - seq[4]
        var pool = [answer + 1, answer - 1, answer + 2, answer - 2, answer + diff, answer - diff / 2,
                    seq[4] + seq[4] - seq[3], answer + 10, answer - 10].filter { $0 > 0 && $0 != answer }
        pool = Array(Set(pool)).shuffled()
        var options = [answer]
        for value in pool where options.count < 4 && !options.contains(value) {
            options.append(value)
        }
        var bump = 3
        while options.count < 4 {
            if !options.contains(answer + bump) { options.append(answer + bump) }
            bump += 1
        }
        return SeriesQuestion(shown: shown, answer: answer, options: options.shuffled(), rule: rule)
    }
}
