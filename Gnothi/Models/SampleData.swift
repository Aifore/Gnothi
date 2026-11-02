import Foundation
import SwiftData

/// 生成半年左右的模拟记录，方便体验「历程」页面（仅调试菜单中使用）
enum SampleData {
    static func load(into context: ModelContext, owner: Member?) {
        let me = owner ?? MemberBootstrap.ensure(context: context, currentID: "")
        let partner = Member(name: "阿青", relation: "伴侣", colorIndex: 2, hairStyle: 2)
        let kid = Member(name: "小树", relation: "孩子", colorIndex: 3, hairStyle: 3)
        context.insert(partner)
        context.insert(kid)

        generate(for: me, context: context, trend: 1.0)
        generate(for: partner, context: context, trend: 0.4)
        generate(for: kid, context: context, trend: 0.7, includeClinical: false)
        try? context.save()
    }

    private static func generate(for member: Member, context: ModelContext, trend: Double, includeClinical: Bool = true) {
        let cal = Calendar.current
        let now = Date.now
        let memberID = member.id

        func daysAgo(_ d: Int, hour: Int = 21) -> Date {
            let base = cal.date(byAdding: .day, value: -d, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: base) ?? base
        }

        func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { min(max(v, lo), hi) }

        // 大五人格：每 45 天一次，「情绪稳定」与「外向性」逐渐上升
        if case .likert(let items, _) = TestCatalog.bigFive.kind {
            let notes = ["刚换了新环境，有点紧张。", "开始每周跑步了，感觉不错。", "出去旅行了一趟，打开了很多。", "这阶段比较平稳。"]
            for (step, ago) in [180, 135, 90, 45, 3].enumerated() {
                let progress = Double(step) / 4 * trend
                let answers = items.map { item -> Int in
                    var lean = 0.0
                    if item.dimension == 3 { lean = -1 + 2 * progress }
                    if item.dimension == 0 { lean = -0.5 + progress }
                    if item.dimension == 4 { lean = 0.8 }
                    let target = 3 + (item.reversed ? -lean : lean) + Double.random(in: -1.2...1.2)
                    return clamp(Int(target.rounded()), 1, 5)
                }
                let record = TestCatalog.bigFive.makeRecord(answers: answers, duration: Double.random(in: 240...420),
                                                            memberID: memberID, date: daysAgo(ago))
                record.note = notes[step % notes.count]
                context.insert(record)
            }
        }

        // PHQ-9 / GAD-7：每两周一次，分数逐渐下降
        if includeClinical {
            for (i, ago) in stride(from: 168, through: 0, by: -14).enumerated() {
                let pressure = max(0, 1.6 - Double(i) * 0.12 * trend)
                let phq = (0..<9).map { idx -> Int in
                    idx == 8 ? 0 : clamp(Int((pressure + Double.random(in: -0.8...0.8)).rounded()), 0, 3)
                }
                context.insert(TestCatalog.phq9.makeRecord(answers: phq, duration: 80, memberID: memberID,
                                                           date: daysAgo(ago, hour: 22)))
                let gad = (0..<7).map { _ in clamp(Int((pressure + Double.random(in: -0.8...0.8)).rounded()), 0, 3) }
                context.insert(TestCatalog.gad7.makeRecord(answers: gad, duration: 60, memberID: memberID,
                                                           date: daysAgo(ago, hour: 22)))
            }
        }

        // 数字推理：每周一次，逐渐进步
        for (i, ago) in stride(from: 70, through: 0, by: -7).enumerated() {
            let skill = min(0.95, 0.45 + Double(i) * 0.05 * trend)
            let answers = (0..<TestCatalog.reasoningCount).map { _ in Double.random(in: 0...1) < skill ? 1 : 0 }
            context.insert(TestCatalog.reasoning.makeRecord(answers: answers, duration: Double.random(in: 120...260),
                                                            memberID: memberID, date: daysAgo(ago, hour: 12)))
        }

        // 心情：最近 60 天，大约 70% 的日子有记录
        let moodNotes = ["", "", "今天阳光很好", "有点累", "和家人吃了顿好饭", "睡得不太好", "完成了一件拖了很久的事"]
        for ago in 0..<60 where Double.random(in: 0...1) < 0.7 {
            let base = 3.0 + Double(60 - ago) / 60 * 0.8 * trend
            let mood = clamp(Int((base + Double.random(in: -1.6...1.4)).rounded()), 1, 5)
            let tags = Array(MoodScale.tags.shuffled().prefix(Int.random(in: 0...2)))
            context.insert(MoodEntry(memberID: memberID, date: daysAgo(ago, hour: Int.random(in: 9...22)), mood: mood,
                                     note: moodNotes.randomElement() ?? "", tags: tags))
        }
    }
}
