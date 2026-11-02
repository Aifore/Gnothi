import SwiftUI
import SwiftData

/// 页面右上角的「当前记录成员」按钮
struct MemberSwitcherButton: View {
    let member: Member?
    @State private var showPicker = false

    var body: some View {
        Button { showPicker = true } label: {
            HStack(spacing: 8) {
                AvatarView(member: member).frame(width: 32, height: 32)
                Text(member?.name ?? "我")
                    .font(.app(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.subInk)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(Theme.card))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $showPicker) {
            MemberPickerSheet()
                .presentationDetents([.medium, .large])
                .macSheetSize(width: 460, height: 560)
        }
    }
}

struct MemberPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Store.self) private var store
    @Query(sort: \Member.createdAt) private var members: [Member]
    @Query private var records: [TestRecord]
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var editing: MemberEditTarget?
    @State private var showPaywall = false

    private var current: Member? { members.current(id: currentMemberID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("选择这次为谁记录。每个成员的测试和心情彼此独立。")
                        .font(.app(13))
                        .foregroundStyle(Theme.subInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    ForEach(members) { member in
                        let count = records.filter { $0.memberID == member.id }.count
                        HStack(spacing: 14) {
                            Button {
                                currentMemberID = member.id.uuidString
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    AvatarView(member: member).frame(width: 48, height: 48)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(member.name).font(.app(17, .semibold)).foregroundStyle(Theme.ink)
                                        Text("\(member.relation) · \(count) 次测试")
                                            .font(.app(12))
                                            .foregroundStyle(Theme.subInk)
                                    }
                                    Spacer()
                                    if member.id == current?.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Theme.leaf)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button { editing = .edit(member) } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.subInk)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Theme.background))
                            }
                            .buttonStyle(.plain)
                        }
                        .card(padding: 14)
                    }

                    Button {
                        if store.canAddMember(currentCount: members.count) {
                            editing = .new
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 48, height: 48)
                                .background(Circle().strokeBorder(Theme.line, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])))
                            Text("添加成员").font(.app(16, .semibold))
                            Spacer()
                            if !store.canAddMember(currentCount: members.count) {
                                Chip(text: "Pro", tint: Theme.butter, systemImage: "lock.fill")
                            }
                        }
                        .foregroundStyle(Theme.ink)
                        .card(padding: 14)
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("家庭成员")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.foregroundStyle(Theme.ink)
                }
            }
            .sheet(item: $editing) { target in
                MemberEditorView(target: target)
                    .macSheetSize(width: 500, height: 720)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .macSheetSize(width: 520, height: 760)
            }
        }
    }
}

enum MemberEditTarget: Identifiable {
    case new
    case edit(Member)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let m): return m.id.uuidString
        }
    }
}

struct MemberEditorView: View {
    let target: MemberEditTarget
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Member.createdAt) private var members: [Member]
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""

    @State private var name = ""
    @State private var relation = "家人"
    @State private var colorIndex = 1
    @State private var hairStyle = 0
    @State private var confirmDelete = false
    @State private var loaded = false

    private var existing: Member? {
        if case .edit(let m) = target { return m }
        return nil
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    AvatarView(colorIndex: colorIndex, hairStyle: hairStyle)
                        .frame(width: 120, height: 120)
                        .animation(.spring(response: 0.4), value: colorIndex)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("名字").font(.app(15, .semibold)).foregroundStyle(Theme.ink)
                        TextField("例如：小树、妈妈", text: $name)
                            .font(.app(17))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.background))
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("关系").font(.app(15, .semibold)).foregroundStyle(Theme.ink)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                            ForEach(AvatarPalette.relations, id: \.self) { item in
                                TagToggle(text: item, selected: relation == item, tint: AvatarPalette.color(colorIndex)) {
                                    relation = item
                                }
                            }
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("头像").font(.app(15, .semibold)).foregroundStyle(Theme.ink)
                        HStack(spacing: 12) {
                            ForEach(AvatarPalette.colors.indices, id: \.self) { i in
                                Button { colorIndex = i } label: {
                                    Circle()
                                        .fill(AvatarPalette.colors[i])
                                        .frame(width: 34, height: 34)
                                        .overlay(Circle().stroke(Theme.ink, lineWidth: colorIndex == i ? 2.5 : 0).padding(-4))
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        HStack(spacing: 10) {
                            ForEach(AvatarPalette.hairStyles.indices, id: \.self) { i in
                                Button { hairStyle = i } label: {
                                    VStack(spacing: 6) {
                                        AvatarView(colorIndex: colorIndex, hairStyle: i)
                                            .frame(width: 54, height: 54)
                                            .overlay(Circle().stroke(Theme.ink, lineWidth: hairStyle == i ? 2.5 : 0).padding(-3))
                                        Text(AvatarPalette.hairStyles[i])
                                            .font(.app(11))
                                            .foregroundStyle(Theme.subInk)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .card()
                    .sensoryFeedback(.selection, trigger: colorIndex * 10 + hairStyle)

                    Button("保存", action: save)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(trimmedName.isEmpty)
                        .opacity(trimmedName.isEmpty ? 0.5 : 1)

                    if existing != nil && members.count > 1 {
                        Button("删除这位成员", role: .destructive) { confirmDelete = true }
                            .font(.app(15, .medium))
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(existing == nil ? "添加成员" : "编辑成员")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.foregroundStyle(Theme.subInk)
                }
            }
            .confirmationDialog("删除「\(existing?.name ?? "")」？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除成员及其全部记录", role: .destructive, action: deleteMember)
            } message: {
                Text("这位成员的所有测试和心情记录都会被永久删除。")
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let m = existing {
            name = m.name
            relation = m.relation
            colorIndex = m.colorIndex
            hairStyle = m.hairStyle
        } else {
            colorIndex = members.count % AvatarPalette.colors.count
            hairStyle = members.count % AvatarPalette.hairStyles.count
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        if let m = existing {
            m.name = trimmedName
            m.relation = relation
            m.colorIndex = colorIndex
            m.hairStyle = hairStyle
        } else {
            let m = Member(name: trimmedName, relation: relation, colorIndex: colorIndex, hairStyle: hairStyle)
            context.insert(m)
            currentMemberID = m.id.uuidString
        }
        try? context.save()
        dismiss()
    }

    private func deleteMember() {
        guard let m = existing else { return }
        let wasCurrent = m.id.uuidString == currentMemberID
        let fallback = members.first { $0.id != m.id }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if wasCurrent, let fallback { currentMemberID = fallback.id.uuidString }
            MemberBootstrap.delete(m, context: context)
        }
    }
}
