import SwiftUI

/// PHQ-9 与 GAD-7：由 Pfizer 资助开发，可免费使用，无需授权。
extension TestCatalog {
    private static let frequencyOptions = [
        LikertOption(label: "完全没有", value: 0),
        LikertOption(label: "有几天", value: 1),
        LikertOption(label: "一半以上的天数", value: 2),
        LikertOption(label: "几乎每天", value: 3),
    ]

    private static func sumScore(_ answers: [Int]) -> (scores: [Double], total: Double) {
        let total = Double(answers.reduce(0, +))
        return ([total], total)
    }

    private static let commonAdvice = [
        "保持规律的作息，尽量在固定时间入睡和起床",
        "每天出门走走，晒晒太阳，做 20 分钟轻度运动",
        "和信任的人聊聊最近的感受",
    ]

    // MARK: PHQ-9

    static let phq9: PsychTest = {
        let texts = [
            "做事时提不起劲，或者没有兴趣",
            "感到心情低落、沮丧或绝望",
            "入睡困难、睡不安稳，或者睡得太多",
            "感觉疲倦，或者没有活力",
            "食欲不振，或者吃得太多",
            "觉得自己很糟糕，觉得自己很失败，或者让自己和家人失望",
            "很难集中注意力，比如阅读或看视频的时候",
            "动作或说话慢到别人能察觉，或者正好相反：烦躁、坐立不安，比平时更爱动来动去",
            "有不如死掉，或者用某种方式伤害自己的念头",
        ]
        let bands = [
            Band(upTo: 4, label: "情绪状态良好", short: "良好", color: Theme.sage,
                 summary: "最近两周，你的情绪整体平稳，没有明显的抑郁表现。继续保持对自己的关注。"),
            Band(upTo: 9, label: "轻度低落", short: "轻度", color: Theme.butter,
                 summary: "你最近可能有些疲惫或低落，这很常见。留意自己的状态，给自己一些休息和放松的时间。"),
            Band(upTo: 14, label: "中度低落", short: "中度", color: Theme.peach,
                 summary: "最近的低落情绪已经在影响你的生活。建议和信任的人聊聊，也可以考虑寻求心理咨询师的帮助。"),
            Band(upTo: 19, label: "中重度低落", short: "中重", color: Theme.rose,
                 summary: "你最近承受着不小的情绪困扰。建议尽快联系专业的心理咨询师或精神科医生，你值得被好好照顾。"),
            Band(upTo: 27, label: "重度低落", short: "重度", color: Theme.berry,
                 summary: "你现在可能非常辛苦。请尽快寻求专业帮助，去医院精神心理科就诊。你并不孤单，帮助就在身边。"),
        ]
        return PsychTest(
            id: "phq9",
            title: "情绪自评",
            subtitle: "PHQ-9 · 抑郁情绪筛查",
            category: .emotion,
            art: .moodCloud,
            tint: Theme.sky,
            minutes: 2,
            intro: "PHQ-9 是全球广泛使用的抑郁情绪筛查量表，用来回顾你最近两周的情绪与身体状态。\n\n建议每两周测一次，在「历程」里看看自己的情绪变化。",
            prompt: "过去两周里，以下情况困扰你的频率是？",
            kind: .likert(items: texts.map { LikertItem(text: $0, dimension: 0, reversed: false) },
                          options: TestCatalog.frequencyOptions),
            dimensions: [Dimension(name: "抑郁情绪", color: Theme.sky)],
            bands: bands,
            chartMax: 27,
            retestDays: 14,
            source: "量表：PHQ-9（Kroenke, Spitzer & Williams, 2001），免费使用",
            score: TestCatalog.sumScore,
            evaluate: { record in
                let band = bands.first { Int(record.total) <= $0.upTo } ?? bands[bands.count - 1]
                let selfHarm = record.answers.count > 8 && record.answers[8] > 0
                var advice = TestCatalog.commonAdvice
                if record.total >= 10 { advice.append("考虑预约心理咨询，或去医院精神心理科做专业评估") }
                return Evaluation(
                    headline: band.label,
                    scoreText: "\(Int(record.total)) / 27 分",
                    summary: band.summary,
                    color: band.color,
                    advice: advice,
                    showsCrisisSupport: selfHarm || record.total >= 15
                )
            }
        )
    }()

    // MARK: GAD-7

    static let gad7: PsychTest = {
        let texts = [
            "感到紧张、焦虑或心神不宁",
            "无法停止或控制担忧",
            "对各种各样的事情担忧过多",
            "很难放松下来",
            "坐立不安，难以安静地坐着",
            "变得容易烦恼或急躁",
            "感到害怕，好像有可怕的事情要发生",
        ]
        let bands = [
            Band(upTo: 4, label: "内心平静", short: "平静", color: Theme.sage,
                 summary: "最近两周，你没有明显的焦虑困扰，内心相对平和。"),
            Band(upTo: 9, label: "轻度焦虑", short: "轻度", color: Theme.butter,
                 summary: "你最近可能有些紧张和担心。试试深呼吸、正念练习，或者把担心的事写下来。"),
            Band(upTo: 14, label: "中度焦虑", short: "中度", color: Theme.peach,
                 summary: "焦虑已经在影响你的日常生活。建议找人倾诉，也可以考虑寻求心理咨询师的帮助。"),
            Band(upTo: 21, label: "重度焦虑", short: "重度", color: Theme.rose,
                 summary: "你最近承受着较强的焦虑。建议尽快寻求专业帮助，焦虑是可以被有效治疗的。"),
        ]
        return PsychTest(
            id: "gad7",
            title: "焦虑自评",
            subtitle: "GAD-7 · 焦虑情绪筛查",
            category: .emotion,
            art: .calmWave,
            tint: Theme.sage,
            minutes: 2,
            intro: "GAD-7 是常用的焦虑情绪筛查量表，用来回顾你最近两周的紧张与担忧程度。\n\n建议每两周测一次，记录情绪的起伏。",
            prompt: "过去两周里，以下情况困扰你的频率是？",
            kind: .likert(items: texts.map { LikertItem(text: $0, dimension: 0, reversed: false) },
                          options: TestCatalog.frequencyOptions),
            dimensions: [Dimension(name: "焦虑情绪", color: Theme.sage)],
            bands: bands,
            chartMax: 21,
            retestDays: 14,
            source: "量表：GAD-7（Spitzer et al., 2006），免费使用",
            score: TestCatalog.sumScore,
            evaluate: { record in
                let band = bands.first { Int(record.total) <= $0.upTo } ?? bands[bands.count - 1]
                var advice = ["每天花 5 分钟做腹式呼吸：吸气 4 秒，停 4 秒，呼气 6 秒"] + TestCatalog.commonAdvice
                if record.total >= 10 { advice.append("考虑预约心理咨询，或去医院做专业评估") }
                return Evaluation(
                    headline: band.label,
                    scoreText: "\(Int(record.total)) / 21 分",
                    summary: band.summary,
                    color: band.color,
                    advice: advice,
                    showsCrisisSupport: record.total >= 15
                )
            }
        )
    }()
}
