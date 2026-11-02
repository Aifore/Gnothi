import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDocument: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.data }
            .suggestedFileName("Gnothi-导出.json")
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TestRecord.date, order: .reverse) private var records: [TestRecord]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \Member.createdAt) private var members: [Member]
    @Environment(Store.self) private var store
    @AppStorage("lockEnabled") private var lockEnabled = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var confirmWipe = false
    @State private var showAbout = false
    @State private var showPaywall = false
    @State private var editing: MemberEditTarget?
    @State private var notice: String?

    private var streak: Int {
        let cal = Calendar.current
        let days = Set(records.map { cal.startOfDay(for: $0.date) } + moods.map { cal.startOfDay(for: $0.date) })
        var count = 0
        var day = cal.startOfDay(for: .now)
        if !days.contains(day), let yesterday = cal.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        while days.contains(day) {
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    private var daysKnown: Int {
        guard let first = (records.map(\.date) + moods.map(\.date)).min() else { return 0 }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: first), to: cal.startOfDay(for: .now)).day ?? 0
        return days + 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    HStack(spacing: 10) {
                        StatTile(value: "\(members.count)", label: "家庭成员", tint: Theme.peach)
                        StatTile(value: "\(streak)", label: "连续记录（天）", tint: Theme.butter)
                        StatTile(value: "\(daysKnown)", label: "认识自己（天）", tint: Theme.sky)
                    }

                    proCard

                    settingsGroup(title: "家庭成员") {
                        ForEach(members) { member in
                            Button { editing = .edit(member) } label: {
                                HStack(spacing: 14) {
                                    AvatarView(member: member).frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.name).font(.app(16, .medium)).foregroundStyle(Theme.ink)
                                        Text("\(member.relation) · \(records.filter { $0.memberID == member.id }.count) 次测试 · \(moods.filter { $0.memberID == member.id }.count) 条心情")
                                            .font(.app(12))
                                            .foregroundStyle(Theme.subInk)
                                    }
                                    Spacer()
                                    if member.id.uuidString == currentMemberID {
                                        Chip(text: "当前", tint: Theme.sage)
                                    }
                                    chevron
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Theme.line)
                        }
                        Button {
                            if store.canAddMember(currentCount: members.count) {
                                editing = .new
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            SettingsRow(icon: "plus", tint: Theme.sage, title: "添加成员",
                                        subtitle: store.isPro ? "为家人建立独立的记录" : "免费版可记录 \(Store.freeMemberLimit) 位成员") {
                                if store.canAddMember(currentCount: members.count) {
                                    chevron
                                } else {
                                    Chip(text: "Pro", tint: Theme.butter, systemImage: "lock.fill")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    settingsGroup(title: "隐私与提醒") {
                        SettingsRow(icon: "faceid", tint: Theme.lavender, title: "隐私锁",
                                    subtitle: "打开 App 时需要 \(Platform.biometricName) 或密码") {
                            Toggle("", isOn: lockBinding).labelsHidden().toggleStyle(.switch).tint(Theme.sage)
                        }
                        Divider().overlay(Theme.line)
                        SettingsRow(icon: "bell", tint: Theme.peach, title: "每周提醒",
                                    subtitle: "周日晚 8 点，提醒你看看最近的自己") {
                            Toggle("", isOn: reminderBinding).labelsHidden().toggleStyle(.switch).tint(Theme.sage)
                        }
                    }

                    settingsGroup(title: "我的数据") {
                        ShareLink(item: ExportDocument(data: ExportPayload.make(records: records, moods: moods, members: members)),
                                  preview: SharePreview("Gnothi 数据导出")) {
                            SettingsRow(icon: "square.and.arrow.up", tint: Theme.sky, title: "导出全部数据",
                                        subtitle: "JSON 格式，可备份或迁移") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.line)
                        Button { confirmWipe = true } label: {
                            SettingsRow(icon: "trash", tint: Theme.rose, title: "删除全部数据",
                                        subtitle: "清空所有成员、测试与心情记录") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        #if DEBUG
                        Divider().overlay(Theme.line)
                        Button {
                            SampleData.load(into: context, owner: members.current(id: currentMemberID))
                            notice = "已载入示例数据（含 2 位示例成员），去「历程」看看吧"
                        } label: {
                            SettingsRow(icon: "wand.and.stars", tint: Theme.butter, title: "载入示例数据",
                                        subtitle: "开发调试用：生成半年的模拟记录") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.line)
                        Button { Task { await store.debugToggleForcePro() } } label: {
                            SettingsRow(icon: "crown", tint: Theme.peach, title: "模拟 Pro（调试）",
                                        subtitle: store.isPro ? "当前：已解锁，点一下恢复免费版" : "当前：免费版，点一下直接解锁") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        #endif
                    }

                    settingsGroup(title: "帮助") {
                        ForEach(Hotline.all) { line in
                            if let url = URL(string: "tel:\(line.tel)") {
                                Link(destination: url) {
                                    SettingsRow(icon: "phone", tint: Theme.sage, title: line.name, subtitle: line.number) {
                                        chevron
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            if line.id != Hotline.all.last?.id {
                                Divider().overlay(Theme.line)
                            }
                        }
                    }

                    settingsGroup(title: "关于") {
                        Button { Task { await restorePurchases() } } label: {
                            SettingsRow(icon: "arrow.clockwise", tint: Theme.butter, title: "恢复购买",
                                        subtitle: "换了手机或重装后，找回已购买的 Pro") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.line)
                        Button { showAbout = true } label: {
                            SettingsRow(icon: "info.circle", tint: Theme.lavender, title: "关于 Gnothi",
                                        subtitle: "设计理念与免责声明") {
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Gnothi 1.0 · 所有数据仅保存在你的设备上")
                        .font(.app(12))
                        .foregroundStyle(Theme.subInk.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth(640)
            }
            .background(Theme.background.ignoresSafeArea())
            .hiddenNavigationBar()
            .confirmationDialog("删除全部数据？", isPresented: $confirmWipe, titleVisibility: .visible) {
                Button("永久删除", role: .destructive, action: wipe)
            } message: {
                Text("所有成员、测试记录和心情记录都会被删除，且无法恢复。建议先导出备份。")
            }
            .sheet(isPresented: $showAbout) { AboutView().macSheetSize(width: 560, height: 700) }
            .sheet(isPresented: $showPaywall) { PaywallView().macSheetSize(width: 520, height: 760) }
            .sheet(item: $editing) { target in MemberEditorView(target: target).macSheetSize(width: 500, height: 720) }

            .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("好的", role: .cancel) {}
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            SeedlingArt().frame(width: 130, height: 130)
            Text("Gnothi")
                .font(.app(30, .bold))
                .foregroundStyle(Theme.ink)
            Text("认识自己")
                .font(.app(15, .medium))
                .foregroundStyle(Theme.subInk)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var proCard: some View {
        if store.isPro {
            HStack(spacing: 14) {
                Sparkle().fill(Theme.butter).frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gnothi Pro 已解锁").font(.app(17, .semibold)).foregroundStyle(Theme.ink)
                    Text("感谢支持！全家人都可以在这里记录").font(.app(13)).foregroundStyle(Theme.subInk)
                }
                Spacer()
            }
            .card()
        } else {
            Button { showPaywall = true } label: {
                HStack(spacing: 14) {
                    HStack(spacing: -10) {
                        AvatarView(colorIndex: 0, hairStyle: 1).frame(width: 36, height: 36)
                        AvatarView(colorIndex: 3, hairStyle: 0).frame(width: 36, height: 36)
                        AvatarView(colorIndex: 2, hairStyle: 2).frame(width: 36, height: 36)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("升级 Gnothi Pro").font(.app(17, .bold)).foregroundStyle(Theme.outline)
                        Text("一次购买，为全家人分别记录").font(.app(13)).foregroundStyle(Theme.outline.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.outline.opacity(0.6))
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .fill(LinearGradient(colors: [Theme.butter.opacity(0.7), Theme.peach.opacity(0.6)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.subInk.opacity(0.6))
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.app(14, .semibold))
                .foregroundStyle(Theme.subInk)
                .padding(.leading, 6)
            VStack(spacing: 12) {
                content()
            }
            .card(padding: 16)
        }
    }

    private var lockBinding: Binding<Bool> {
        Binding(
            get: { lockEnabled },
            set: { newValue in
                if newValue {
                    Task { @MainActor in
                        if !Biometrics.isAvailable {
                            notice = "这台设备没有设置 \(Platform.biometricName) 或锁屏密码，暂时无法开启隐私锁。"
                        } else if await Biometrics.authenticate(reason: "验证身份以开启隐私锁") {
                            lockEnabled = true
                        }
                    }
                } else {
                    lockEnabled = false
                }
            }
        )
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { newValue in
                if newValue {
                    Task { @MainActor in
                        if await Reminder.enable() {
                            reminderEnabled = true
                        } else {
                            notice = "没有通知权限。可以在「设置 › 通知 › Gnothi」中开启。"
                        }
                    }
                } else {
                    Reminder.disable()
                    reminderEnabled = false
                }
            }
        )
    }

    @MainActor
    private func restorePurchases() async {
        await store.restore()
        if let error = store.errorMessage {
            notice = error
            store.errorMessage = nil
        } else if store.isPro {
            notice = "已恢复 Gnothi Pro ✨"
        }
    }

    private func wipe() {
        try? context.delete(model: TestRecord.self)
        try? context.delete(model: MoodEntry.self)
        try? context.delete(model: Member.self)
        try? context.save()
        let member = MemberBootstrap.ensure(context: context, currentID: "")
        currentMemberID = member.id.uuidString
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let tint: Color
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.outline)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.45)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.app(16, .medium))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.app(12))
                        .foregroundStyle(Theme.subInk)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeroArt().frame(height: 170)

                    section("Gnothi 是什么",
                            "Gnothi 取自古希腊德尔斐神庙上的箴言「γνῶθι σεαυτόν」，意思是「认识你自己」。\n\n人不是一个固定的分数。我们会成长、会低落、也会重新出发。Gnothi 希望把每一次测试和每一次心情都记录下来，连成一条属于你的心灵轨迹。")

                    section("量表与来源",
                            "• 大五人格：IPIP 50 题（公有领域）\n• 情绪自评：PHQ-9（免费使用）\n• 焦虑自评：GAD-7（免费使用）\n• 数字推理：程序随机生成的原创题目")

                    section("隐私",
                            "所有数据只保存在你的设备上，不会上传到任何服务器。你可以随时导出或彻底删除。")

                    section("免责声明",
                            TestCatalog.disclaimer + "\n\n数字推理是思维练习，不是标准化的智商测验。如果你正处于危机之中，请立即联系心理援助热线或拨打 120。")
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("关于")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }.foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.app(17, .semibold))
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(.app(15))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(5)
        }
        .card()
    }
}
