import SwiftUI
import SwiftData

/// 测试全流程：介绍 → 答题 → 结果（完成即自动保存进历程）
struct TestFlowView: View {
    let test: PsychTest
    let member: Member?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var stage: Stage = .intro
    @State private var record: TestRecord?
    @State private var confirmExit = false

    enum Stage { case intro, questions, result }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .intro:
                TestIntroView(test: test,
                              member: member,
                              onStart: { withAnimation(.easeInOut) { stage = .questions } },
                              onClose: { dismiss() })
                    .transition(.opacity)
            case .questions:
                Group {
                    switch test.kind {
                    case .likert(let items, let options):
                        LikertRunner(test: test, items: items, options: options,
                                     onFinish: finish, onClose: { confirmExit = true })
                    case .reasoning(let count):
                        ReasoningRunner(test: test, count: count,
                                        onFinish: finish, onClose: { confirmExit = true })
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .result:
                if let record {
                    ResultView(record: record, test: test, onDone: { dismiss() })
                        .transition(.opacity)
                }
            }
        }
        .alert("要退出吗？", isPresented: $confirmExit) {
            Button("继续作答", role: .cancel) {}
            Button("退出", role: .destructive) { dismiss() }
        } message: {
            Text("本次作答进度不会被保存。")
        }
    }

    private func finish(answers: [Int], duration: TimeInterval) {
        let newRecord = test.makeRecord(answers: answers, duration: duration, memberID: member?.id)
        context.insert(newRecord)
        try? context.save()
        record = newRecord
        withAnimation(.easeInOut) { stage = .result }
    }
}

// MARK: - Intro

struct TestIntroView: View {
    let test: PsychTest
    let member: Member?
    var onStart: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let member {
                    HStack(spacing: 8) {
                        AvatarView(member: member).frame(width: 30, height: 30)
                        Text("本次为 \(member.name) 记录")
                            .font(.app(14, .medium))
                            .foregroundStyle(Theme.subInk)
                    }
                    .padding(.leading, 4)
                    .padding(.trailing, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.card))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.card))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Blob(seed: 21, points: 8, variance: 0.14)
                            .fill(test.tint.opacity(0.28))
                            .frame(width: 220, height: 190)
                        TestArt(kind: test.art)
                            .frame(width: 150, height: 150)
                    }
                    .padding(.top, 4)

                    VStack(spacing: 8) {
                        Text(test.title)
                            .font(.app(30, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(test.subtitle)
                            .font(.app(15))
                            .foregroundStyle(Theme.subInk)
                    }

                    HStack(spacing: 10) {
                        Chip(text: "\(test.questionCount) 题", tint: test.tint, systemImage: "list.bullet")
                        Chip(text: "约 \(test.minutes) 分钟", tint: test.tint, systemImage: "clock")
                        Chip(text: "建议每 \(test.retestDays) 天", tint: test.tint, systemImage: "arrow.clockwise")
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text(test.intro)
                            .font(.app(16))
                            .foregroundStyle(Theme.ink.opacity(0.85))
                            .lineSpacing(5)
                        Label("凭第一感觉作答，答案没有对错", systemImage: "sparkles")
                            .font(.app(14, .medium))
                            .foregroundStyle(Theme.subInk)
                    }
                    .card()

                    Text(test.source)
                        .font(.app(11))
                        .foregroundStyle(Theme.subInk.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            Button("开始", action: onStart)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Shared pieces

struct TestTopBar: View {
    let progress: Double
    let label: String
    var tint: Color
    var onBack: (() -> Void)?
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { onBack?() } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 38, height: 38)
                }
                .opacity(onBack == nil ? 0 : 1)
                .disabled(onBack == nil)

                Spacer()
                Text(label)
                    .font(.app(15, .semibold))
                    .foregroundStyle(Theme.subInk)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .frame(width: 38, height: 38)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.ink)

            ProgressCapsule(progress: progress, tint: tint)
        }
    }
}

struct OptionButton: View {
    let label: String
    let selected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.app(17, .medium))
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? tint : Theme.line)
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? tint.opacity(0.2) : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? tint : Theme.line, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - Likert runner

struct LikertRunner: View {
    let test: PsychTest
    let items: [LikertItem]
    let options: [LikertOption]
    var onFinish: ([Int], TimeInterval) -> Void
    var onClose: () -> Void

    @State private var index = 0
    @State private var answers: [Int?]
    @State private var advancing = false
    @State private var start = Date()

    init(test: PsychTest, items: [LikertItem], options: [LikertOption],
         onFinish: @escaping ([Int], TimeInterval) -> Void, onClose: @escaping () -> Void) {
        self.test = test
        self.items = items
        self.options = options
        self.onFinish = onFinish
        self.onClose = onClose
        _answers = State(initialValue: Array(repeating: nil, count: items.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            TestTopBar(progress: Double(index) / Double(max(items.count, 1)),
                       label: "\(index + 1) / \(items.count)",
                       tint: test.tint,
                       onBack: backAction,
                       onClose: onClose)

            Spacer(minLength: 20)

            VStack(spacing: 16) {
                if let prompt = test.prompt {
                    Text(prompt)
                        .font(.app(14, .medium))
                        .foregroundStyle(Theme.subInk)
                }
                Text(items[index].text)
                    .font(.app(25, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .id(index)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { i in
                    OptionButton(label: options[i].label,
                                 selected: answers[index] == options[i].value,
                                 tint: test.tint) {
                        select(options[i].value)
                    }
                    // 键盘 1~5 快速作答（Mac / 外接键盘）
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))), modifiers: [])
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var backAction: (() -> Void)? {
        if index > 0 {
            return { goBack() }
        }
        return nil
    }

    private func goBack() {
        guard !advancing, index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { index -= 1 }
    }

    private func select(_ value: Int) {
        guard !advancing else { return }
        answers[index] = value
        advancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if index < items.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) { index += 1 }
                advancing = false
            } else {
                onFinish(answers.map { $0 ?? 0 }, Date().timeIntervalSince(start))
            }
        }
    }
}

// MARK: - Reasoning runner

struct ReasoningRunner: View {
    let test: PsychTest
    var onFinish: ([Int], TimeInterval) -> Void
    var onClose: () -> Void

    @State private var questions: [SeriesQuestion]
    @State private var index = 0
    @State private var results: [Int] = []
    @State private var picked: Int?
    @State private var start = Date()

    init(test: PsychTest, count: Int,
         onFinish: @escaping ([Int], TimeInterval) -> Void, onClose: @escaping () -> Void) {
        self.test = test
        self.onFinish = onFinish
        self.onClose = onClose
        _questions = State(initialValue: SeriesGenerator.makeSet(count: count))
    }

    var body: some View {
        let question = questions[index]
        VStack(spacing: 0) {
            TestTopBar(progress: Double(index) / Double(max(questions.count, 1)),
                       label: "\(index + 1) / \(questions.count)",
                       tint: test.tint,
                       onBack: nil,
                       onClose: onClose)

            TimelineView(.periodic(from: start, by: 1)) { context in
                Label(elapsed(at: context.date), systemImage: "timer")
                    .font(.app(14, .medium))
                    .foregroundStyle(Theme.subInk)
                    .monospacedDigit()
            }
            .padding(.top, 14)

            Spacer(minLength: 20)

            VStack(spacing: 22) {
                Text("找出规律，选出下一个数")
                    .font(.app(15, .medium))
                    .foregroundStyle(Theme.subInk)
                SeriesRow(numbers: question.shown, tint: test.tint)
            }
            .id(question.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            Spacer(minLength: 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.element) { offset, option in
                    Button { pick(option, for: question) } label: {
                        Text("\(option)")
                            .font(.app(26, .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(picked == option ? test.tint.opacity(0.35) : Theme.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(picked == option ? test.tint : Theme.line, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(PressableStyle())
                    .keyboardShortcut(KeyEquivalent(Character(String(offset + 1))), modifiers: [])
                }
            }
            .sensoryFeedback(.selection, trigger: picked)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func elapsed(at date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(start)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func pick(_ option: Int, for question: SeriesQuestion) {
        guard picked == nil else { return }
        picked = option
        results.append(option == question.answer ? 1 : 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if index < questions.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    index += 1
                    picked = nil
                }
            } else {
                onFinish(results, Date().timeIntervalSince(start))
            }
        }
    }
}

struct SeriesRow: View {
    let numbers: [Int]
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(numbers.indices, id: \.self) { i in
                tile(Text("\(numbers[i])"), fill: Theme.card, stroke: Theme.line)
            }
            tile(Text("?"), fill: tint.opacity(0.35), stroke: tint)
        }
    }

    private func tile(_ text: Text, fill: Color, stroke: Color) -> some View {
        text
            .font(.app(22, .bold))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(stroke, lineWidth: 1.5))
    }
}
