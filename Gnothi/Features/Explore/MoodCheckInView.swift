import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var mood: Int
    @State private var tags: Set<String> = []
    @State private var note = ""
    @State private var saved = false

    let member: Member?

    init(initialMood: Int, member: Member?) {
        self.member = member
        _mood = State(initialValue: initialMood)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        if let member {
                            HStack(spacing: 6) {
                                AvatarView(member: member).frame(width: 22, height: 22)
                                Text("为 \(member.name) 记录").font(.app(13, .medium)).foregroundStyle(Theme.subInk)
                            }
                        }
                        MoodFace(mood: mood)
                            .frame(width: 140, height: 140)
                            .animation(.spring(response: 0.45, dampingFraction: 0.6), value: mood)
                        Text(MoodScale.label(mood))
                            .font(.app(26, .bold))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                    }
                    .padding(.top, 8)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { m in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { mood = m }
                            } label: {
                                MoodFace(mood: m)
                                    .frame(width: 48, height: 48)
                                    .scaleEffect(mood == m ? 1.12 : 0.88)
                                    .opacity(mood == m ? 1 : 0.5)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: mood)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("和什么有关？")
                            .font(.app(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                            ForEach(MoodScale.tags, id: \.self) { tag in
                                TagToggle(text: tag, selected: tags.contains(tag), tint: MoodScale.color(mood)) {
                                    if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                                }
                            }
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("想说点什么")
                            .font(.app(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        TextField("今天发生了什么？此刻在想什么？", text: $note, axis: .vertical)
                            .font(.app(16))
                            .lineLimit(3...8)
                    }
                    .card()

                    Button("记录下来", action: save)
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("记录心情")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Theme.subInk)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func save() {
        let ordered = MoodScale.tags.filter { tags.contains($0) }
        context.insert(MoodEntry(memberID: member?.id, mood: mood, note: note.trimmingCharacters(in: .whitespacesAndNewlines), tags: ordered))
        try? context.save()
        saved = true
        dismiss()
    }
}
