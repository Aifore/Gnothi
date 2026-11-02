import SwiftUI
import StoreKit
import Observation

/// 内购：年订阅 + 终身买断，任意一个即解锁 Pro
@Observable
final class Store {
    static let yearlyID = "com.example.gnothi.pro.yearly"
    static let lifetimeID = "com.example.gnothi.pro.lifetime"
    static let productIDs = [yearlyID, lifetimeID]
    /// 免费版可创建的成员数
    static let freeMemberLimit = 1

    private(set) var products: [Product] = []
    private(set) var isPro = false
    private(set) var isLoading = false
    private(set) var purchasingID: String?
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // 离线时先用上次的结果，避免已付费用户被拦住
        isPro = UserDefaults.standard.bool(forKey: "cachedIsPro")
        updatesTask = Task { @MainActor [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task { @MainActor [weak self] in await self?.load() }
    }

    var yearly: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetime: Product? { products.first { $0.id == Self.lifetimeID } }

    func canAddMember(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeMemberLimit
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
        } catch {
            errorMessage = "暂时无法连接 App Store，请稍后再试。"
        }
        await refreshEntitlements()
    }

    @MainActor
    func refreshEntitlements() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               Self.productIDs.contains(transaction.productID) {
                pro = true
            }
        }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugForcePro") { pro = true }
        #endif
        isPro = pro
        UserDefaults.standard.set(pro, forKey: "cachedIsPro")
    }

    #if DEBUG
    /// 调试用：不经过 App Store，直接切换 Pro 状态（Release 构建中不存在）
    @MainActor
    func debugToggleForcePro() async {
        let key = "debugForcePro"
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: key), forKey: key)
        await refreshEntitlements()
    }
    #endif

    @MainActor
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchasingID = product.id
        defer { purchasingID = nil }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "购买验证失败，请联系我们。"
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .pending:
                errorMessage = "购买正在等待确认，完成后会自动解锁。"
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "恢复失败：\(error.localizedDescription)"
        }
        await refreshEntitlements()
        if !isPro && errorMessage == nil {
            errorMessage = "没有找到可恢复的购买记录。"
        }
    }
}
