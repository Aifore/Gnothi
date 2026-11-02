import SwiftUI

enum TestCategory: String, CaseIterable, Identifiable {
    case personality = "人格"
    case emotion = "情绪"
    case cognition = "认知"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .personality: return "了解你是怎样的人"
        case .emotion: return "照见最近的情绪状态"
        case .cognition: return "活动一下你的大脑"
        }
    }
}

struct Dimension {
    let name: String
    let color: Color
}

/// 单分量表的分级（例如 PHQ-9 的轻度 / 中度…）
struct Band {
    let upTo: Int
    let label: String
    let short: String
    let color: Color
    let summary: String
}

struct LikertItem {
    let text: String
    let dimension: Int
    let reversed: Bool
}

struct LikertOption {
    let label: String
    let value: Int
}

struct DimensionScore: Identifiable {
    let dimension: Dimension
    /// 0~100
    let value: Double
    let note: String
    var id: String { dimension.name }
}

struct Evaluation {
    var headline: String
    var scoreText: String
    var summary: String
    var color: Color
    var dimensionScores: [DimensionScore] = []
    var advice: [String] = []
    var showsCrisisSupport = false
}

/// 测试定义：配置驱动，新增测试只需要加一个定义
struct PsychTest: Identifiable {
    enum Kind {
        case likert(items: [LikertItem], options: [LikertOption])
        case reasoning(count: Int)
    }

    let id: String
    let title: String
    let subtitle: String
    let category: TestCategory
    let art: ArtKind
    let tint: Color
    let minutes: Int
    let intro: String
    /// 每题上方的引导语（例如「过去两周里…」）
    let prompt: String?
    let kind: Kind
    let dimensions: [Dimension]
    let bands: [Band]
    /// 趋势图 Y 轴上限
    let chartMax: Double
    /// 建议重测间隔（天）
    let retestDays: Int
    let source: String
    let score: ([Int]) -> (scores: [Double], total: Double)
    let evaluate: (TestRecord) -> Evaluation

    var questionCount: Int {
        switch kind {
        case .likert(let items, _): return items.count
        case .reasoning(let count): return count
        }
    }

    func makeRecord(answers: [Int], duration: TimeInterval, memberID: UUID?, date: Date = .now) -> TestRecord {
        let result = score(answers)
        return TestRecord(testID: id, memberID: memberID, date: date, answers: answers,
                          scores: result.scores, total: result.total, duration: duration)
    }

    func band(for total: Double) -> Band? {
        bands.first { Int(total.rounded()) <= $0.upTo } ?? bands.last
    }
}

enum TestCatalog {
    static let all: [PsychTest] = [bigFive, phq9, gad7, reasoning]

    private static let index: [String: PsychTest] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func test(id: String) -> PsychTest? { index[id] }

    static func tests(in category: TestCategory) -> [PsychTest] {
        all.filter { $0.category == category }
    }

    static let disclaimer = "本测试结果仅供自我了解与参考，不构成任何医学或心理诊断。如有困扰，请寻求专业帮助。"
}
