import Foundation
import StoreKit

class StoreKitManager: NSObject, ObservableObject {
    // 发布的属性用于UI更新
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var error: String?
    
    // 定义我们的产品ID
    // 注意：这些ID需要在App Store Connect中进行配置
    enum ProductID: String, CaseIterable {
        case monthlySubscription = "com.deepseek.app.subscription.monthly"
        case quarterlySubscription = "com.deepseek.app.subscription.quarterly"
        case yearlySubscription = "com.deepseek.app.subscription.yearly"
        
        var displayName: String {
            switch self {
            case .monthlySubscription:
                return "月度会员"
            case .quarterlySubscription:
                return "季度会员"
            case .yearlySubscription:
                return "年度会员"
            }
        }
    }
    
    // 更新检查器
    private var updateListenerTask: Task<Void, Error>?
    
    // 初始化方法
    override init() {
        super.init()
        
        // 启动监听事务更新
        updateListenerTask = listenForTransactions()
        
        // 加载产品
        Task {
            await loadProducts()
        }
        
        // 检查已购买的产品
        Task {
            await updatePurchasedProducts()
        }
    }
    
    // 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 持续监听交易更新
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // 更新用户的已购买产品列表
                    await self.updatePurchasedProducts()
                    
                    // 完成交易
                    await transaction.finish()
                } catch {
                    print("交易验证失败: \(error)")
                }
            }
        }
    }
    
    // 加载产品信息
    @MainActor
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            // 获取所有产品ID
            let productIDs = ProductID.allCases.map { $0.rawValue }
            
            // 请求产品信息
            let storeProducts = try await Product.products(for: productIDs)
            
            // 按照我们需要的顺序排序产品
            self.products = storeProducts.sorted { product1, product2 in
                // 获取产品价格
                let price1 = product1.price
                let price2 = product2.price
                
                // 按价格升序排序（从低到高）
                return price1 < price2
            }
            
            print("✅ 成功加载\(self.products.count)个产品")
            
            // 在DEBUG模式下，如果没有产品，创建模拟产品数据
            #if DEBUG
            if self.products.isEmpty {
                print("⚠️ 未找到真实产品，创建模拟产品数据")
                self.createMockProducts()
            }
            #endif
            
        } catch {
            self.error = "加载产品信息失败: \(error.localizedDescription)"
            print("❌ \(self.error ?? "")")
            
            // 在DEBUG模式下，创建模拟产品数据
            #if DEBUG
            print("⚠️ 创建模拟产品数据")
            self.createMockProducts()
            #endif
        }
        
        isLoading = false
    }
    
    // 在DEBUG模式下创建模拟产品数据
    #if DEBUG
    private func createMockProducts() {
        print("🔍 开始创建模拟产品数据")
        self.error = nil
        
        // 清除任何现有产品以避免混淆
        DispatchQueue.main.async {
            if self.products.isEmpty {
                print("📱 开发模式：使用模拟价格数据")
                self.error = nil
                
                // 在控制台输出价格信息，检查是否有问题
                let monthlyPlan = MembershipViewModel.MembershipPlan.monthly
                let quarterlyPlan = MembershipViewModel.MembershipPlan.quarterly
                let yearlyPlan = MembershipViewModel.MembershipPlan.yearly
                
                print("📊 模拟价格信息:")
                print("月度: \(monthlyPlan.mockPrice)")
                print("季度: \(quarterlyPlan.mockPrice)")
                print("年度: \(yearlyPlan.mockPrice)")
            }
        }
    }
    #endif
    
    // 更新已购买的产品列表
    @MainActor
    func updatePurchasedProducts() async {
        // 创建一个临时集合存储已购买的产品ID
        var purchasedIDs = Set<String>()
        
        // 获取所有当前交易
        for await result in Transaction.currentEntitlements {
            do {
                // 检查交易是否通过验证
                let transaction = try checkVerified(result)
                
                // 如果是通过验证的，将其产品ID添加到已购买集合中
                purchasedIDs.insert(transaction.productID)
                
                print("✅ 找到已购买产品: \(transaction.productID)")
            } catch {
                print("❌ 交易验证失败: \(error.localizedDescription)")
            }
        }
        
        // 更新UI中显示的已购买产品集合
        self.purchasedProductIDs = purchasedIDs
    }
    
    // 购买产品
    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        // 开始加载状态
        isLoading = true
        error = nil
        
        do {
            // 尝试购买产品
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                // 检查交易是否通过验证
                let transaction = try checkVerified(verificationResult)
                
                // 更新已购买的产品列表
                await updatePurchasedProducts()
                
                // 完成交易
                await transaction.finish()
                
                print("✅ 已成功购买: \(product.id)")
                isLoading = false
                return transaction
                
            case .userCancelled:
                // 用户取消了购买
                print("ℹ️ 用户取消了购买")
                isLoading = false
                return nil
                
            case .pending:
                // 购买处于待定状态（例如需要家长批准）
                error = "购买请求待处理中。"
                print("⚠️ 购买待批准")
                isLoading = false
                return nil
                
            default:
                // 其他状态，应该不会发生
                error = "购买请求返回了未知状态。"
                print("❓ 未知的购买状态")
                isLoading = false
                return nil
            }
        } catch {
            // 捕获购买过程中发生的错误
            self.error = "购买失败: \(error.localizedDescription)"
            print("❌ 购买错误: \(error.localizedDescription)")
            isLoading = false
            throw error
        }
    }
    
    // 恢复购买
    @MainActor
    func restorePurchases() async {
        isLoading = true
        error = nil
        
        print("🔄 开始恢复购买...")
        
        // AppStore会自动知道用户已经购买了什么
        await updatePurchasedProducts()
        
        print("✅ 购买恢复完成")
        isLoading = false
    }
    
    // 检查交易是否通过了验证
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // 检查交易是否被苹果服务器验证
        switch result {
        case .unverified:
            // 交易未通过验证，可能是篡改或伪造
            throw StoreError.failedVerification
        case .verified(let safe):
            // 交易通过验证，返回安全的交易对象
            return safe
        }
    }
    
    // 获取产品的本地化价格
    func formatPrice(for product: Product) -> String {
        let price = product.displayPrice
        print("🏷️ 格式化价格: \(price) 来自产品: \(product.id)")
        return price
    }
    
    // 检查用户是否有活跃的订阅
    func hasActiveSubscription() -> Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    // 获取用户当前的订阅产品
    func getCurrentSubscription() -> Product? {
        guard hasActiveSubscription() else { return nil }
        
        // 找到当前已购买的第一个产品
        for product in products {
            if purchasedProductIDs.contains(product.id) {
                return product
            }
        }
        
        return nil
    }
    
    // 根据产品ID查找产品
    func product(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }
    
    // 获取订阅到期日期
    func getExpirationDate() async -> Date? {
        // 获取当前所有交易
        for await result in Transaction.currentEntitlements {
            do {
                // 验证交易
                let transaction = try checkVerified(result)
                
                // 检查交易过期日期
                if let expirationDate = transaction.expirationDate {
                    return expirationDate
                } else if transaction.revocationDate == nil {
                    // 如果没有显式的到期日期但也没有被撤销，计算一个估计的到期日期
                    // 假设大部分订阅是按月计算的，使用30天作为默认周期
                    let estimatedPeriod = Calendar.current.date(byAdding: .day, value: 30, to: transaction.purchaseDate)
                    return estimatedPeriod
                }
                
                // 对于非订阅类型的交易，可以根据需要添加其他逻辑
                
            } catch {
                print("❌ 获取到期日期时发生错误: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    // 取消订阅
    func cancelSubscription() {
        // 无法直接通过代码取消订阅，需要引导用户去App Store设置中操作
        print("ℹ️ 用户需要前往App Store设置页面来取消订阅")
    }
    
    // 清理资源
    deinit {
        // 取消后台任务
        updateListenerTask?.cancel()
    }
}

// 自定义错误类型
enum StoreError: Error {
    case failedVerification
    case unknown
    
    var description: String {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        case .unknown:
            return "未知错误"
        }
    }
} 