import SwiftUI
import SwiftData

@main
struct GnothiApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        #if os(macOS)
        .defaultSize(width: 1120, height: 800)
        #endif
        .modelContainer(for: [Member.self, TestRecord.self, MoodEntry.self])
    }
}

struct RootView: View {
    @AppStorage("lockEnabled") private var lockEnabled = false
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var unlocked = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            mainContent

            if lockEnabled && !unlocked {
                LockView { unlocked = true }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { unlocked = false }
        }
        .onAppear {
            let member = MemberBootstrap.ensure(context: context, currentID: currentMemberID)
            currentMemberID = member.id.uuidString
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        MacSidebarRoot()
        #else
        TabView {
                ExploreView()
                    .tabItem { Label("探索", systemImage: "sparkles") }
                JourneyView()
                    .tabItem { Label("历程", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
                ProfileView()
                    .tabItem { Label("我的", systemImage: "leaf") }
            }
            .tint(Theme.ink)
        #endif
    }
}

#if os(macOS)
// MARK: - Mac：侧边栏布局

enum SidebarItem: Hashable {
    case explore, journey, profile
}

struct MacSidebarRoot: View {
    @Query(sort: \Member.createdAt) private var members: [Member]
    @AppStorage(AppKeys.currentMember) private var currentMemberID = ""
    @State private var selection: SidebarItem? = .explore

    private var current: Member? { members.current(id: currentMemberID) }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label("探索", systemImage: "sparkles").tag(SidebarItem.explore)
                    Label("历程", systemImage: "point.topleft.down.to.point.bottomright.curvepath").tag(SidebarItem.journey)
                    Label("我的", systemImage: "leaf").tag(SidebarItem.profile)
                }
                Section("正在为谁记录") {
                    ForEach(members) { member in
                        Button {
                            currentMemberID = member.id.uuidString
                        } label: {
                            HStack(spacing: 8) {
                                AvatarView(member: member).frame(width: 24, height: 24)
                                Text(member.name).lineLimit(1)
                                Spacer()
                                if member.id == current?.id {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.leaf)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    AppMark().frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Gnothi").font(.app(13, .bold)).foregroundStyle(Theme.ink)
                        Text("认识自己").font(.app(11)).foregroundStyle(Theme.subInk)
                    }
                    Spacer()
                }
                .padding(14)
            }
        } detail: {
            switch selection ?? .explore {
            case .explore: ExploreView()
            case .journey: JourneyView()
            case .profile: ProfileView()
            }
        }
        .tint(Theme.ink)
    }
}
#endif
