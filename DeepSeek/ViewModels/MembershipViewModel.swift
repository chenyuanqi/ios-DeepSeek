import Foundation
import Combine
import StoreKit

class MembershipViewModel: ObservableObject {
    // 会员状态
    @Published var isMember = false
    @Published var currentPlan: MembershipPlan?
    @Published var expirationDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // StoreKit管理器
    @Published var storeManager = StoreKitManager()
    
    // 取消令牌存储
    private var cancellables = Set<AnyCancellable>()
    
    // 会员计划枚举
    enum MembershipPlan: String, Codable, Hashable {
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .monthly:
                return "月度会员"
            case .quarterly:
                return "季度会员"
            case .yearly:
                return "年度会员"
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .monthly:
                return 30 * 24 * 60 * 60 // 30天（秒）
            case .quarterly:
                return 90 * 24 * 60 * 60 // 90天（秒）
            case .yearly:
                return 365 * 24 * 60 * 60 // 365天（秒）
            }
        }
        
        // 模拟价格显示（开发模式下使用）
        var mockPrice: String {
            switch self {
            case .monthly:
                return "¥28/月"
            case .quarterly:
                return "¥78/季"
            case .yearly:
                return "¥238/年"
            }
        }
        
        // 模拟折扣显示（开发模式下使用）
        var mockDiscount: String? {
            switch self {
            case .monthly:
                return nil
            case .quarterly:
                return "减¥6"
            case .yearly:
                return "减¥98"
            }
        }
        
        // 转换为StoreKit产品ID
        var productID: StoreKitManager.ProductID {
            switch self {
            case .monthly:
                return .monthlySubscription
            case .quarterly:
                return .quarterlySubscription
            case .yearly:
                return .yearlySubscription
            }
        }
        
        // 从StoreKit产品ID创建
        static func fromProductID(_ productID: String) -> MembershipPlan? {
            switch productID {
            case StoreKitManager.ProductID.monthlySubscription.rawValue:
                return .monthly
            case StoreKitManager.ProductID.quarterlySubscription.rawValue:
                return .quarterly
            case StoreKitManager.ProductID.yearlySubscription.rawValue:
                return .yearly
            default:
                return nil
            }
        }
    }
    
    init() {
        // 观察StoreKit购买状态的变化
        storeManager.$purchasedProductIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] productIDs in
                guard let self = self else { return }
                
                // 检查是否有任何订阅产品
                self.isMember = !productIDs.isEmpty
                
                // 如果有，设置当前订阅计划
                if self.isMember {
                    // 找到第一个订阅产品
                    if let productID = productIDs.first, 
                       let plan = MembershipPlan.fromProductID(productID) {
                        self.currentPlan = plan
                        
                        // 获取订阅到期日期
                        Task {
                            if let expDate = await self.storeManager.getExpirationDate() {
                                DispatchQueue.main.async {
                                    self.expirationDate = expDate
                                    self.saveMembershipStatus()
                                }
                            }
                        }
                    }
                } else {
                    // 如果没有订阅，清除相关信息
                    self.currentPlan = nil
                    self.expirationDate = nil
                    self.clearMembershipStatus()
                }
                
                print("📱 会员状态更新: \(self.isMember ? "已订阅" : "未订阅"), 计划: \(self.currentPlan?.displayName ?? "无")")
            }
            .store(in: &cancellables)
        
        // 监听StoreKit错误
        storeManager.$error
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        // 初始化时加载本地保存的会员信息
        loadMembershipStatus()
    }
    
    // 检查会员状态
    func checkMembershipStatus() {
        isLoading = true
        errorMessage = nil
        
        // 首先从本地加载缓存的会员信息
        loadMembershipStatus()
        
        // 然后从StoreKit更新最新状态
        Task {
            await storeManager.updatePurchasedProducts()
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    // 订阅会员
    func subscribe(plan: MembershipPlan, completion: @escaping (Bool) -> Void) {
        guard let product = storeManager.product(for: plan.productID) else {
            errorMessage = "无法找到对应的产品信息"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 使用StoreKit进行真实购买
        Task {
            do {
                if let _ = try await storeManager.purchase(product) {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(true)
                    }
                } else {
                    // 用户取消购买或其他原因
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(false)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "购买失败: \(error.localizedDescription)"
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }
    
    // 恢复购买
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        Task {
            await storeManager.restorePurchases()
            DispatchQueue.main.async {
                completion(self.storeManager.hasActiveSubscription())
            }
        }
    }
    
    // 取消订阅
    func cancelSubscription(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 在App内不能直接取消订阅，需要引导用户到App Store设置
        storeManager.cancelSubscription()
        
        // 标记为已处理（虽然无法直接在应用内取消订阅）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.errorMessage = "请前往App Store设置页面取消订阅"
            completion(false)
        }
    }
    
    // 检查会员是否过期
    func isMembershipExpired() -> Bool {
        guard let expirationDate = expirationDate else {
            return true
        }
        
        return Date() > expirationDate
    }
    
    // 获取剩余天数
    func getRemainingDays() -> Int? {
        guard let expirationDate = expirationDate, !isMembershipExpired() else {
            return nil
        }
        
        let currentDate = Date()
        let timeInterval = expirationDate.timeIntervalSince(currentDate)
        
        return Int(timeInterval / (24 * 60 * 60))
    }
    
    // 保存会员状态到UserDefaults
    private func saveMembershipStatus() {
        if let plan = currentPlan {
            UserDefaults.standard.set(plan.rawValue, forKey: "membershipPlan")
        }
        
        if let date = expirationDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "membershipExpiration")
        }
        
        UserDefaults.standard.set(isMember, forKey: "isMember")
    }
    
    // 从UserDefaults加载会员状态
    private func loadMembershipStatus() {
        if let planString = UserDefaults.standard.string(forKey: "membershipPlan"),
           let plan = MembershipPlan(rawValue: planString) {
            currentPlan = plan
        }
        
        if let timeInterval = UserDefaults.standard.object(forKey: "membershipExpiration") as? TimeInterval {
            expirationDate = Date(timeIntervalSince1970: timeInterval)
        }
        
        // 本地存储的会员状态作为备用，但StoreKit的状态更准确
        let localIsMember = UserDefaults.standard.bool(forKey: "isMember")
        
        // 如果StoreKit尚未初始化完成，先使用本地存储的状态
        if !storeManager.hasActiveSubscription() && localIsMember && !isMembershipExpired() {
            isMember = true
        } else {
            isMember = storeManager.hasActiveSubscription()
        }
        
        // 检查是否过期
        if isMember && isMembershipExpired() {
            isMember = false
            clearMembershipStatus()
        }
    }
    
    // 清除会员状态
    private func clearMembershipStatus() {
        UserDefaults.standard.removeObject(forKey: "membershipPlan")
        UserDefaults.standard.removeObject(forKey: "membershipExpiration")
        UserDefaults.standard.set(false, forKey: "isMember")
        
        isMember = false
        currentPlan = nil
        expirationDate = nil
    }
} 