import SwiftUI
import SwiftData

enum TimelineItem: Identifiable {
    case test(TestRecord)
    case mood(MoodEntry)

    var id: UUID {
        switch self {
        case .test(let r): return r.id
        case .mood(let m): return m.id
        }
    }

    var date: Date {
        switch self {
        case .test(let r): return r.date
        case .mood(let m): return m.date
        }
    }
}

struct JourneyView: View {
    @Query(sort: \TestRecord.date, order: .reverse) private var allRecords: [TestRecord]
    @Query(sort: \MoodEntry.date, order: .reverse) private var allMoods: [MoodEntry]
    @Query(sort: \Member.createdAt) private var members: [Member]
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var mode = 0

    private var member: Member? { members.current(id: currentMemberID) }
    /// 只显示当前成员的数据
    private var records: [TestRecord] { allRecords.filter { $0.memberID == member?.id } }
    private var moods: [MoodEntry] { allMoods.filter { $0.memberID == member?.id } }

    private var activeDays: Int {
        let cal = Calendar.current
        let days = records.map { cal.startOfDay(for: $0.date) } + moods.map { cal.startOfDay(for: $0.date) }
        return Set(days).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Spacer()
                            MemberSwitcherButton(member: member)
                        }
                        Text(member.map { $0.relation == "我" ? "我的历程" : "\($0.name)的历程" } ?? "我的历程")
                            .font(.app(32, .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("每一次记录，都是一次和自己的重逢")
                            .font(.app(15))
                            .foregroundStyle(Theme.subInk)
                    }
                    .padding(.top, 12)

                    JourneyArt().frame(height: 160)

                    HStack(spacing: 10) {
                        StatTile(value: "\(activeDays)", label: "记录天数", tint: Theme.peach)
                        StatTile(value: "\(records.count)", label: "完成测试", tint: Theme.lavender)
                        StatTile(value: "\(moods.count)", label: "心情记录", tint: Theme.sage)
                    }

                    Picker("视图", selection: $mode) {
                        Text("时间线").tag(0)
                        Text("变化趋势").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if records.isEmpty && moods.isEmpty {
                        EmptyJourney()
                    } else if mode == 0 {
                        TimelineSection(records: records, moods: moods)
                    } else {
                        TrendSection(records: records, moods: moods)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .hiddenNavigationBar()
            .navigationDestination(for: TestRecord.self) { record in
                RecordDetailView(record: record)
            }
        }
    }
}

struct EmptyJourney: View {
    var body: some View {
        VStack(spacing: 14) {
            SeedlingArt().frame(width: 150, height: 150)
            Text("你的历程还是一片空白")
                .font(.app(18, .semibold))
                .foregroundStyle(Theme.ink)
            Text("去「探索」完成第一次测试，\n或者记录一下今天的心情吧")
                .font(.app(14))
                .foregroundStyle(Theme.subInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Timeline

struct TimelineSection: View {
    let records: [TestRecord]
    let moods: [MoodEntry]
    @Environment(\.modelContext) private var context

    private var groups: [(month: Date, items: [TimelineItem])] {
        let cal = Calendar.current
        let items = records.map(TimelineItem.test) + moods.map(TimelineItem.mood)
        let grouped = Dictionary(grouping: items) { item in
            cal.date(from: cal.dateComponents([.year, .month], from: item.date)) ?? item.date
        }
        return grouped
            .map { (month: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 22) {
            ForEach(groups, id: \.month) { group in
                VStack(alignment: .leading, spacing: 0) {
                    Text(Formatters.month.string(from: group.month))
                        .font(.app(16, .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 12)
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { offset, item in
                        TimelineRow(item: item, isLast: offset == group.items.count - 1)
                            .contextMenu {
                                Button("删除这条记录", systemImage: "trash", role: .destructive) {
                                    delete(item)
                                }
                            }
                    }
                }
            }
        }
    }

    private func delete(_ item: TimelineItem) {
        withAnimation {
            switch item {
            case .test(let r): context.delete(r)
            case .mood(let m): context.delete(m)
            }
            try? context.save()
        }
    }
}

struct TimelineRow: View {
    let item: TimelineItem
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Theme.background, lineWidth: 3))
                    .padding(.top, 22)
                if !isLast {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            content
                .padding(.bottom, 12)
        }
    }

    private var dotColor: Color {
        switch item {
        case .test(let r): return TestCatalog.test(id: r.testID)?.tint ?? Theme.lavender
        case .mood(let m): return MoodScale.color(m.mood)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item {
        case .test(let record):
            if let test = TestCatalog.test(id: record.testID) {
                NavigationLink(value: record) {
                    TestRow(record: record, test: test)
                }
                .buttonStyle(PressableStyle())
            }
        case .mood(let entry):
            MoodRow(entry: entry)
        }
    }
}

private struct TestRow: View {
    let record: TestRecord
    let test: PsychTest

    var body: some View {
        let eval = test.evaluate(record)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(test.tint.opacity(0.22))
                    TestArt(kind: test.art).padding(6)
                }
                .frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.title)
                        .font(.app(13, .medium))
                        .foregroundStyle(Theme.subInk)
                    Text(eval.headline)
                        .font(.app(17, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Formatters.day.string(from: record.date))
                        .font(.app(12, .medium))
                        .foregroundStyle(Theme.subInk)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.subInk.opacity(0.6))
                }
            }
            if !record.note.isEmpty {
                Text("“\(record.note)”")
                    .font(.app(14))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .card(padding: 14)
    }
}

private struct MoodRow: View {
    let entry: MoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                MoodFace(mood: entry.mood).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("心情 · \(MoodScale.label(entry.mood))")
                        .font(.app(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(Formatters.dayTime.string(from: entry.date))
                        .font(.app(12))
                        .foregroundStyle(Theme.subInk)
                }
                Spacer()
            }
            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags.prefix(4), id: \.self) { tag in
                        Chip(text: tag, tint: MoodScale.color(entry.mood))
                    }
                }
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.app(14))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .lineLimit(4)
            }
        }
        .card(padding: 14)
    }
}

// MARK: - Detail

struct RecordDetailView: View {
    @Bindable var record: TestRecord
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let test = TestCatalog.test(id: record.testID) {
                ResultView(record: record, test: test, onDone: nil)
            } else {
                Text("未知的测试类型").foregroundStyle(Theme.subInk)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { confirmDelete = true } label: {
                    Image(systemName: "trash")
                }
                .tint(Theme.subInk)
            }
        }
        .confirmationDialog("删除这条测试记录？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                let target = record
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    context.delete(target)
                    try? context.save()
                }
            }
        } message: {
            Text("删除后无法恢复。")
        }
        .onDisappear { try? context.save() }
    }
}
