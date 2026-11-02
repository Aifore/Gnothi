import SwiftUI
import SwiftData

struct MoodDraft: Identifiable {
    let id = UUID()
    let mood: Int
}

struct ExploreView: View {
    @Query(sort: \TestRecord.date, order: .reverse) private var records: [TestRecord]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \Member.createdAt) private var members: [Member]
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var activeTest: PsychTest?
    @State private var moodDraft: MoodDraft?

    private var member: Member? { members.current(id: currentMemberID) }

    private var memberRecords: [TestRecord] {
        records.filter { $0.memberID == member?.id }
    }

    private var todayMoods: [MoodEntry] {
        moods.filter { $0.memberID == member?.id && Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    MoodPromptCard(todayMoods: todayMoods) { moodDraft = MoodDraft(mood: $0) }

                    ForEach(TestCategory.allCases) { category in
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(title: category.rawValue, subtitle: category.subtitle)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                                ForEach(TestCatalog.tests(in: category)) { test in
                                    Button { activeTest = test } label: {
                                        TestCard(test: test, last: memberRecords.first { $0.testID == test.id })
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                    }

                    Text("γνῶθι σεαυτόν · 认识你自己")
                        .font(.app(12))
                        .foregroundStyle(Theme.subInk.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth(860)
            }
            .background(Theme.background.ignoresSafeArea())
            .hiddenNavigationBar()
        }
        .testCover(item: $activeTest) { test in
            TestFlowView(test: test, member: member)
        }
        .sheet(item: $moodDraft) { draft in
            MoodCheckInView(initialMood: draft.mood, member: member)
                .macSheetSize(width: 500, height: 720)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(Formatters.weekday.string(from: .now))
                    .font(.app(14, .medium))
                    .foregroundStyle(Theme.subInk)
                Spacer()
                MemberSwitcherButton(member: member)
            }
            Text(member.map { "\(Formatters.greeting())，\($0.name)" } ?? Formatters.greeting())
                .font(.app(32, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("今天，也来认识一下自己吧")
                .font(.app(16))
                .foregroundStyle(Theme.subInk)
            HeroArt()
                .frame(height: 190)
                .padding(.top, 8)
        }
        .padding(.top, 12)
    }
}

// MARK: - Mood prompt

struct MoodPromptCard: View {
    let todayMoods: [MoodEntry]
    var onPick: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayMoods.isEmpty ? "今天感觉怎么样？" : "今天已记录 \(todayMoods.count) 次")
                        .font(.app(18, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(todayMoods.isEmpty ? "轻点一张小脸，记录此刻的心情" : "心情随时会变，想记就再记一笔")
                        .font(.app(13))
                        .foregroundStyle(Theme.subInk)
                }
                Spacer()
                if let last = todayMoods.first {
                    Chip(text: "\(Formatters.time.string(from: last.date)) · \(MoodScale.label(last.mood))",
                         tint: MoodScale.color(last.mood))
                }
            }
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { mood in
                    Button { onPick(mood) } label: {
                        VStack(spacing: 6) {
                            MoodFace(mood: mood).frame(width: 46, height: 46)
                            Text(MoodScale.label(mood))
                                .font(.app(12, .medium))
                                .foregroundStyle(Theme.subInk)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .card()
    }
}

// MARK: - Test card

struct TestCard: View {
    let test: PsychTest
    let last: TestRecord?

    private var isDue: Bool {
        guard let last else { return false }
        let days = Calendar.current.dateComponents([.day], from: last.date, to: .now).day ?? 0
        return days >= test.retestDays
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(test.tint.opacity(0.22))
                TestArt(kind: test.art)
                    .padding(8)
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text(test.title)
                    .font(.app(18, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(test.subtitle)
                    .font(.app(13))
                    .foregroundStyle(Theme.subInk)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: "\(test.questionCount) 题 · 约 \(test.minutes) 分钟", tint: Theme.line)
                    if let last {
                        if isDue {
                            Chip(text: "可以再测了", tint: test.tint, systemImage: "arrow.clockwise")
                        } else {
                            Chip(text: Formatters.relativeString(last.date), tint: test.tint, systemImage: "checkmark")
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.subInk.opacity(0.6))
        }
        .card(padding: 14)
    }
}
