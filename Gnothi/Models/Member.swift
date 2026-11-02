import SwiftUI
import SwiftData

/// 家庭成员角色：所有记录都按成员隔离
@Model
final class Member {
    var id: UUID
    var name: String
    var relation: String
    var colorIndex: Int
    var hairStyle: Int
    var createdAt: Date

    init(name: String, relation: String, colorIndex: Int = 0, hairStyle: Int = 0, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.colorIndex = colorIndex
        self.hairStyle = hairStyle
        self.createdAt = createdAt
    }

    var color: Color { AvatarPalette.color(colorIndex) }
}

enum AppKeys {
    static let currentMember = "currentMemberID"
}

enum AvatarPalette {
    static let colors: [Color] = [Theme.peach, Theme.sage, Theme.lavender, Theme.sky, Theme.butter, Theme.rose]
    static let hairStyles = ["短发", "丸子头", "长发", "毛线帽"]
    static let relations = ["我", "伴侣", "爸爸", "妈妈", "孩子", "兄弟姐妹", "家人", "朋友"]

    static func color(_ i: Int) -> Color { colors[((i % colors.count) + colors.count) % colors.count] }
}

extension Array where Element == Member {
    /// 当前选中的成员；找不到时退回第一个
    func current(id: String) -> Member? {
        first { $0.id.uuidString == id } ?? first
    }
}

enum MemberBootstrap {
    /// 确保至少有一个成员，并把没有归属的旧记录归到第一个成员名下。返回应当选中的成员。
    @discardableResult
    static func ensure(context: ModelContext, currentID: String) -> Member {
        let members = (try? context.fetch(FetchDescriptor<Member>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        let owner: Member
        if let first = members.first {
            owner = first
        } else {
            owner = Member(name: "我", relation: "我", colorIndex: 0, hairStyle: 1)
            context.insert(owner)
        }

        let tests = (try? context.fetch(FetchDescriptor<TestRecord>())) ?? []
        for record in tests where record.memberID == nil { record.memberID = owner.id }
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        for entry in moods where entry.memberID == nil { entry.memberID = owner.id }
        try? context.save()

        return members.first { $0.id.uuidString == currentID } ?? owner
    }

    /// 删除成员及其全部记录
    static func delete(_ member: Member, context: ModelContext) {
        let id = member.id
        let tests = (try? context.fetch(FetchDescriptor<TestRecord>())) ?? []
        for record in tests where record.memberID == id { context.delete(record) }
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        for entry in moods where entry.memberID == id { context.delete(entry) }
        context.delete(member)
        try? context.save()
    }
}
