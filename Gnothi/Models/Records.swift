import Foundation
import SwiftData

/// 一次测试记录。保存原始答案和量表版本，便于日后重新计分，保证历程可比。
@Model
final class TestRecord {
    var id: UUID
    /// 所属成员（按成员隔离数据）
    var memberID: UUID?
    var testID: String
    var date: Date
    /// 原始作答（Likert 选项值；推理题为 1=答对 / 0=答错）
    var answers: [Int]
    /// 各维度得分（大五为 0~100；单分量表只有一个值）
    var scores: [Double]
    var total: Double
    /// 用时（秒）
    var duration: Double
    /// 测后随笔：「此刻的我」
    var note: String
    var scaleVersion: Int

    init(testID: String,
         memberID: UUID? = nil,
         date: Date = .now,
         answers: [Int],
         scores: [Double],
         total: Double,
         duration: Double,
         note: String = "",
         scaleVersion: Int = 1) {
        self.id = UUID()
        self.memberID = memberID
        self.testID = testID
        self.date = date
        self.answers = answers
        self.scores = scores
        self.total = total
        self.duration = duration
        self.note = note
        self.scaleVersion = scaleVersion
    }
}

/// 一次心情打卡
@Model
final class MoodEntry {
    var id: UUID
    var memberID: UUID?
    var date: Date
    /// 1~5
    var mood: Int
    var note: String
    var tags: [String]

    init(memberID: UUID? = nil, date: Date = .now, mood: Int, note: String = "", tags: [String] = []) {
        self.id = UUID()
        self.memberID = memberID
        self.date = date
        self.mood = mood
        self.note = note
        self.tags = tags
    }
}

// MARK: - Export

struct ExportPayload: Codable {
    struct Test: Codable {
        let member: String
        let test: String
        let date: Date
        let answers: [Int]
        let scores: [Double]
        let total: Double
        let durationSeconds: Double
        let note: String
    }

    struct Mood: Codable {
        let member: String
        let date: Date
        let mood: Int
        let tags: [String]
        let note: String
    }

    let app: String
    let exportedAt: Date
    let tests: [Test]
    let moods: [Mood]

    static func make(records: [TestRecord], moods: [MoodEntry], members: [Member]) -> Data {
        let names = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })
        func name(_ id: UUID?) -> String { id.flatMap { names[$0] } ?? "" }
        let payload = ExportPayload(
            app: "Gnothi",
            exportedAt: .now,
            tests: records.map {
                Test(member: name($0.memberID), test: $0.testID, date: $0.date, answers: $0.answers, scores: $0.scores,
                     total: $0.total, durationSeconds: $0.duration, note: $0.note)
            },
            moods: moods.map { Mood(member: name($0.memberID), date: $0.date, mood: $0.mood, tags: $0.tags, note: $0.note) }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(payload)) ?? Data()
    }
}
