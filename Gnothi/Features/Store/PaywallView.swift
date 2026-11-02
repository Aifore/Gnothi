import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = Store.lifetimeID

    private let benefits: [(icon: String, title: String, detail: String)] = [
        ("person.2", "不限成员", "为家人分别建立角色，各自的数据互不干扰"),
        ("chart.xyaxis.line", "每个人独立的历程", "时间线、变化曲线、前后对比，人人都有"),
        ("sparkles", "后续新增的全部测试", "持续更新的量表和练习，一次解锁"),
        ("heart", "支持独立开发", "没有广告，数据只留在你的设备上"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        HStack(spacing: -14) {
                            AvatarView(colorIndex: 0, hairStyle: 1).frame(width: 64, height: 64)
                            AvatarView(colorIndex: 3, hairStyle: 0).frame(width: 72, height: 72).zIndex(1)
                            AvatarView(colorIndex: 2, hairStyle: 2).frame(width: 64, height: 64)
                        }
                        Text("Gnothi Pro")
                            .font(.app(30, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("一次购买，全家都能记录自己的心灵轨迹")
                            .font(.app(15))
                            .foregroundStyle(Theme.subInk)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(benefits, id: \.title) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.outline)
                                    .frame(width: 34, height: 34)
                                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.lavender.opacity(0.45)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.app(16, .semibold)).foregroundStyle(Theme.ink)
                                    Text(item.detail).font(.app(13)).foregroundStyle(Theme.subInk)
                                }
                            }
                        }
                    }
                    .card()

                    if store.products.isEmpty {
                        VStack(spacing: 10) {
                            if store.isLoading {
                                ProgressView()
                            } else {
                                Text("暂时无法获取价格")
                                    .font(.app(14))
                                    .foregroundStyle(Theme.subInk)
                                Button("重试") { Task { await store.load() } }
                                    .font(.app(15, .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 12) {
                            if let lifetime = store.lifetime {
                                PlanCard(product: lifetime, title: "终身版", note: "一次买断，永久使用",
                                         badge: "最划算", selected: selectedID == lifetime.id) {
                                    selectedID = lifetime.id
                                }
                            }
                            if let yearly = store.yearly {
                                PlanCard(product: yearly, title: "年度订阅", note: trialText(yearly) ?? "按年自动续费，可随时取消",
                                         badge: nil, selected: selectedID == yearly.id) {
                                    selectedID = yearly.id
                                }
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task {
                                guard let product = store.products.first(where: { $0.id == selectedID }) else { return }
                                if await store.purchase(product) { dismiss() }
                            }
                        } label: {
                            if store.purchasingID != nil {
                                ProgressView().tint(Theme.background)
                            } else {
                                Text(selectedID == Store.lifetimeID ? "立即解锁" : "开始订阅")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(store.products.isEmpty || store.purchasingID != nil)

                        Button("恢复购买") { Task { await store.restore() } }
                            .font(.app(14, .medium))
                            .foregroundStyle(Theme.subInk)
                    }

                    Text("订阅会在到期前 24 小时内自动续费，可在「设置 › Apple ID › 订阅」中随时取消。终身版为一次性购买。")
                        .font(.app(11))
                        .foregroundStyle(Theme.subInk.opacity(0.8))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 16) {
                        Link("使用条款", destination: AppInfo.termsURL)
                        Link("隐私政策", destination: AppInfo.privacyURL)
                    }
                    .font(.app(12, .medium))
                    .foregroundStyle(Theme.subInk)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .foregroundStyle(Theme.ink)
                }
            }
            .alert(store.errorMessage ?? "", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            }
            .onChange(of: store.isPro) { _, pro in
                if pro { dismiss() }
            }
        }
    }

    private func trialText(_ product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        let unit: String
        switch period.unit {
        case .day: unit = "天"
        case .week: unit = "周"
        case .month: unit = "个月"
        case .year: unit = "年"
        @unknown default: unit = ""
        }
        return "前 \(period.value) \(unit)免费试用，之后按年续费"
    }
}

private struct PlanCard: View {
    let product: Product
    let title: String
    let note: String
    let badge: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Theme.leaf : Theme.line)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title).font(.app(17, .semibold)).foregroundStyle(Theme.ink)
                        if let badge { Chip(text: badge, tint: Theme.peach) }
                    }
                    Text(note).font(.app(12)).foregroundStyle(Theme.subInk)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.app(20, .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? Theme.sage.opacity(0.18) : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selected ? Theme.leaf : Theme.line, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableStyle())
    }
}
