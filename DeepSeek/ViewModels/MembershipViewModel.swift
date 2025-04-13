import Foundation
import Combine
import StoreKit
import PassKit // 添加PassKit用于Apple Pay支持

// 会员错误类型定义
enum MembershipError: Error, LocalizedError {
    case productNotFound
    case applePayNotSupported
    case noPurchasesToRestore
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "找不到对应的产品信息"
        case .applePayNotSupported:
            return "您的设备不支持Apple Pay，请使用标准支付方式"
        case .noPurchasesToRestore:
            return "没有可恢复的购买"
        case .unknown:
            return "未知错误"
        }
    }
}

class MembershipViewModel: ObservableObject {
    // 会员状态
    @Published var isMember = false
    @Published var currentPlan: MembershipPlan?
    @Published var expirationDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPaymentMethod: PaymentMethod = .inAppPurchase
    
    // UI状态
    @Published var isProcessingPurchase = false
    @Published var purchaseSucceeded = false
    @Published var showThankYouView = false
    @Published var showErrorAlert = false
    @Published var showRestoreSuccessAlert = false
    @Published var selectedPlan: MembershipPlan = .monthly
    @Published var subscribedPlan: MembershipPlan?
    @Published var error: Error?
    
    // 计算属性 - 获取选中计划对应的产品
    var productForSelectedPlan: Product? {
        guard !storeKitManager.products.isEmpty else { return nil }
        return storeKitManager.products.first { product in
            return product.id == selectedPlan.productID.rawValue
        }
    }
    
    // StoreKit管理器
    @Published var storeKitManager = StoreKitManager()
    
    // 定义支付方式
    enum PaymentMethod {
        case inAppPurchase // 标准的应用内购买
        case applePay      // Apple Pay支付
    }
    
    // 取消令牌存储
    private var cancellables = Set<AnyCancellable>()
    
    // 会员计划枚举
    enum MembershipPlan: String, Codable, Hashable, CaseIterable {
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
        
        static var allCases: [MembershipPlan] {
            return [.monthly, .quarterly, .yearly]
        }
        
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
        storeKitManager.$purchasedProductIDs
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
                            if let expDate = await self.storeKitManager.getExpirationDate() {
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
        storeKitManager.$error
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
            await storeKitManager.updatePurchasedProducts()
            
            // 验证App Store收据
            let receiptValid = await storeKitManager.verifyReceipt()
            print("📝 收据验证结果: \(receiptValid ? "有效" : "无效")")
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    @MainActor
    func subscribe() async {
        guard !isProcessingPurchase else { return }
        isProcessingPurchase = true
        
        do {
            guard let product = productForSelectedPlan else {
                throw MembershipError.productNotFound
            }
            
            #if targetEnvironment(simulator)
            print("🔍 在模拟器环境中尝试购买")
            switch selectedPaymentMethod {
            case .inAppPurchase:
                // 在模拟器中仍然使用标准StoreKit模拟购买（通过.storekit文件）
                print("模拟器标准购买...")
                _ = try await storeKitManager.purchase(product) // 使用标准购买触发.storekit流程
                purchaseSucceeded = true
            case .applePay:
                // 检查是否可以使用Apple Pay
                if PKPaymentAuthorizationController.canMakePayments() {
                    // 在模拟器中尝试调用Apple Pay流程
                    print("模拟器尝试Apple Pay...")
                    let result = try await storeKitManager.purchaseWithApplePay(product)
                    if result != nil {
                        purchaseSucceeded = true
                    }
                } else {
                    throw MembershipError.applePayNotSupported
                }
            }
            #else
            // 真实设备上的购买逻辑
            switch selectedPaymentMethod {
            case .inAppPurchase:
                // 使用StoreKit进行购买
                let result = try await storeKitManager.purchase(product)
                if result != nil {
                    purchaseSucceeded = true
                }
            case .applePay:
                // 检查是否可以使用Apple Pay
                if PKPaymentAuthorizationController.canMakePayments() {
                    let result = try await storeKitManager.purchaseWithApplePay(product)
                    if result != nil {
                        purchaseSucceeded = true
                    }
                } else {
                    throw MembershipError.applePayNotSupported
                }
            }
            #endif
            
            if purchaseSucceeded {
                print("✅ 购买成功：\(product.displayName)")
                subscribedPlan = selectedPlan
                showThankYouView = true
            }
        } catch {
            print("❌ 购买失败：\(error.localizedDescription)")
            self.error = error
            showErrorAlert = true
        }
        
        isProcessingPurchase = false
    }
    
    @MainActor
    func restorePurchases() async -> Bool {
        guard !isProcessingPurchase else { return false }
        isProcessingPurchase = true
        
        do {
            #if targetEnvironment(simulator)
            print("🔍 在模拟器环境中模拟恢复购买")
            // 在模拟器中使用模拟恢复功能
            let restoredTransactions = await storeKitManager.restorePurchases()
            
            if restoredTransactions.isEmpty {
                throw MembershipError.noPurchasesToRestore
            }
            
            // 找到恢复的会员等级
            for transaction in restoredTransactions {
                if let plan = MembershipPlan.allCases.first(where: { $0.productID.rawValue == transaction.productID }) {
                    subscribedPlan = plan
                    break
                }
            }
            
            purchaseSucceeded = true
            print("✅ 恢复购买成功")
            #else
            // 真实设备上的恢复购买逻辑
            let restoredTransactions = try await storeKitManager.restorePurchases()
            
            if restoredTransactions.isEmpty {
                throw MembershipError.noPurchasesToRestore
            }
            
            // 找到恢复的会员等级
            for transaction in restoredTransactions {
                if let plan = MembershipPlan.allCases.first(where: { $0.productID.rawValue == transaction.productID }) {
                    subscribedPlan = plan
                    break
                }
            }
            
            purchaseSucceeded = true
            print("✅ 恢复购买成功")
            #endif
            
            if purchaseSucceeded {
                showRestoreSuccessAlert = true
            }
            
            isProcessingPurchase = false
            return purchaseSucceeded
        } catch {
            print("❌ 恢复购买失败：\(error.localizedDescription)")
            self.error = error
            showErrorAlert = true
            
            isProcessingPurchase = false
            return false
        }
    }
    
    // 取消订阅
    func cancelSubscription(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 在App内不能直接取消订阅，需要引导用户到App Store设置
        storeKitManager.cancelSubscription()
        
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
        if !storeKitManager.hasActiveSubscription() && localIsMember && !isMembershipExpired() {
            isMember = true
        } else {
            isMember = storeKitManager.hasActiveSubscription()
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
    
    // 订阅会员
    func subscribe(plan: MembershipPlan, completion: @escaping (Bool) -> Void) {
        selectedPlan = plan
        Task {
            await subscribe()
            completion(purchaseSucceeded)
        }
    }
} 