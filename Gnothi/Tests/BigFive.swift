import SwiftUI

/// 大五人格 · IPIP 50 题（Goldberg, 1992）。IPIP 题库属于公有领域，可自由使用。
extension TestCatalog {
    static let bigFive: PsychTest = {
        let dimensions = [
            Dimension(name: "外向性", color: Theme.peach),
            Dimension(name: "宜人性", color: Theme.rose),
            Dimension(name: "尽责性", color: Theme.sage),
            Dimension(name: "情绪稳定", color: Theme.sky),
            Dimension(name: "开放性", color: Theme.lavender),
        ]

        // (题目, 是否反向计分)
        let grouped: [[(String, Bool)]] = [
            [ // 外向性
                ("我是聚会中的活跃分子", false),
                ("我话不多", true),
                ("和别人在一起时，我感到自在", false),
                ("我习惯待在不显眼的地方", true),
                ("我常常主动开启话题", false),
                ("我没什么话想说", true),
                ("聚会上，我会和很多不同的人交谈", false),
                ("我不喜欢引人注意", true),
                ("成为众人的焦点，我也不介意", false),
                ("在陌生人面前，我很安静", true),
            ],
            [ // 宜人性
                ("我很少关心别人", true),
                ("我对人很感兴趣", false),
                ("我会出言冒犯别人", true),
                ("我能体会别人的感受", false),
                ("我对别人的烦恼不感兴趣", true),
                ("我心肠很软", false),
                ("我对他人并不真正感兴趣", true),
                ("我愿意花时间陪伴别人", false),
                ("我能感受到别人的情绪", false),
                ("我能让别人感到轻松自在", false),
            ],
            [ // 尽责性
                ("我总是提前做好准备", false),
                ("我的东西常常随手乱放", true),
                ("我注重细节", false),
                ("我常把事情弄得一团糟", true),
                ("我会马上把杂事做完", false),
                ("我常忘记把东西放回原处", true),
                ("我喜欢井井有条", false),
                ("我会逃避自己的责任", true),
                ("我按计划行事", false),
                ("我对工作要求严格", false),
            ],
            [ // 情绪稳定（原量表为神经质，这里已换算方向）
                ("我很容易感到压力", true),
                ("大多数时候，我都很放松", false),
                ("我常常为各种事情担心", true),
                ("我很少感到忧郁", false),
                ("我很容易被打扰而心烦", true),
                ("我很容易难过", true),
                ("我的心情经常变化", true),
                ("我的情绪常常起伏不定", true),
                ("我很容易被激怒", true),
                ("我常常感到忧郁", true),
            ],
            [ // 开放性
                ("我的词汇量很丰富", false),
                ("我难以理解抽象的概念", true),
                ("我有生动的想象力", false),
                ("我对抽象的想法不感兴趣", true),
                ("我常有很棒的点子", false),
                ("我的想象力不太好", true),
                ("我理解事物很快", false),
                ("我会使用一些较难的词汇", false),
                ("我会花时间反思事物", false),
                ("我的脑子里满是各种想法", false),
            ],
        ]

        // 五个维度交替出题
        var built: [LikertItem] = []
        for i in 0..<10 {
            for d in 0..<5 {
                let (text, reversed) = grouped[d][i]
                built.append(LikertItem(text: text, dimension: d, reversed: reversed))
            }
        }
        let items = built

        let options = [
            LikertOption(label: "非常不符合", value: 1),
            LikertOption(label: "比较不符合", value: 2),
            LikertOption(label: "说不清", value: 3),
            LikertOption(label: "比较符合", value: 4),
            LikertOption(label: "非常符合", value: 5),
        ]

        let notes: [(high: String, mid: String, low: String)] = [
            ("你从与人相处中获得能量，乐于表达，喜欢热闹。",
             "你在社交与独处之间保持平衡，能根据场合切换状态。",
             "你更享受安静与独处，在小圈子里更自在，习惯先观察再表达。"),
            ("你温和体贴，乐于合作，常把别人的感受放在心上。",
             "你能体谅他人，也能在需要时坚持自己的立场。",
             "你直接、理性，看重事实与效率，不轻易随大流。"),
            ("你有条理、守承诺，习惯计划先行，做事让人放心。",
             "你能在计划与灵活之间切换，重要的事不会掉链子。",
             "你随性灵活，喜欢自发行动，不太被规则束缚。"),
            ("你情绪平稳，面对压力时通常能保持冷静。",
             "你的情绪大体稳定，偶尔会被压力影响。",
             "你感受敏锐、情绪丰富，压力下容易担忧，记得多照顾自己。"),
            ("你好奇心强，富有想象力，喜欢新想法和抽象思考。",
             "你对新事物保持兴趣，同时也重视实际经验。",
             "你务实、脚踏实地，更喜欢熟悉和具体的事物。"),
        ]

        let titles = ["热情的连接者", "温暖的同行者", "可靠的建造者", "沉稳的观察者", "好奇的探索者"]

        return PsychTest(
            id: "bigfive",
            title: "大五人格",
            subtitle: "心理学界最认可的人格模型",
            category: .personality,
            art: .personality,
            tint: Theme.lavender,
            minutes: 6,
            intro: "大五人格从外向性、宜人性、尽责性、情绪稳定和开放性五个维度描绘你的性格。没有好坏之分，每一种组合都是独特的你。\n\n请根据平时真实的自己作答，而不是理想中的自己。",
            prompt: "这句话有多符合你？",
            kind: .likert(items: items, options: options),
            dimensions: dimensions,
            bands: [],
            chartMax: 100,
            retestDays: 90,
            source: "题目来源：IPIP Big-Five Factor Markers（Goldberg, 1992），公有领域",
            score: { answers in
                var sums = Array(repeating: 0.0, count: 5)
                var counts = Array(repeating: 0.0, count: 5)
                for (i, item) in items.enumerated() where i < answers.count {
                    let v = Double(answers[i])
                    sums[item.dimension] += item.reversed ? 6 - v : v
                    counts[item.dimension] += 1
                }
                let scores = (0..<5).map { d in
                    counts[d] > 0 ? (sums[d] / counts[d] - 1) / 4 * 100 : 0
                }
                return (scores, scores.reduce(0, +) / 5)
            },
            evaluate: { record in
                let scores = record.scores.count == 5 ? record.scores : Array(repeating: 50, count: 5)
                let top = scores.indices.max { scores[$0] < scores[$1] } ?? 0
                let dimensionScores = (0..<5).map { d -> DimensionScore in
                    let v = scores[d]
                    let note = v >= 60 ? notes[d].high : (v <= 40 ? notes[d].low : notes[d].mid)
                    return DimensionScore(dimension: dimensions[d], value: v, note: note)
                }
                return Evaluation(
                    headline: titles[top],
                    scoreText: "最突出：\(dimensions[top].name) \(Int(scores[top].rounded()))%",
                    summary: "你最鲜明的特质是「\(dimensions[top].name)」。\(notes[top].high)\n\n人格会随着经历缓慢变化。几个月后再测一次，看看自己有什么不同。",
                    color: dimensions[top].color,
                    dimensionScores: dimensionScores,
                    advice: []
                )
            }
        )
    }()
}
