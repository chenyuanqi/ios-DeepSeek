# DeepSeek AI 应用 - 订阅与 Apple Pay 接入指南（下）

本文档是 DeepSeek AI 应用订阅与 Apple Pay 接入指南的第二部分，继续详细介绍如何实现产品加载、处理购买、集成 Apple Pay 以及管理订阅状态。

## 目录

- [DeepSeek AI 应用 - 订阅与 Apple Pay 接入指南（下）](#deepseek-ai-应用---订阅与-apple-pay-接入指南下)
  - [目录](#目录)
  - [产品加载实现](#产品加载实现)
  - [处理购买流程](#处理购买流程)
  - [Apple Pay 集成](#apple-pay-集成)
    - [1. 检查 Apple Pay 可用性](#1-检查-apple-pay-可用性)
    - [2. 创建 Apple Pay 按钮](#2-创建-apple-pay-按钮)
    - [3. 实现 Apple Pay 支付流程](#3-实现-apple-pay-支付流程)
  - [订阅状态管理](#订阅状态管理)
  - [订阅界面实现](#订阅界面实现)
  - [用量限制实现](#用量限制实现)
  - [测试与调试](#测试与调试)
    - [使用沙盒环境测试](#使用沙盒环境测试)
    - [处理常见错误](#处理常见错误)

## 产品加载实现

首先，我们需要实现 `StoreKitManager` 中加载产品的功能：

```swift
// 加载产品信息
@MainActor
func loadProducts() async {
    // 避免重复加载
    if isLoadingProducts || productsLoaded {
        return
    }
    
    isLoadingProducts = true
    
    do {
        // 使用 StoreKit 2 API 请求产品
        let storeProducts = try await Product.products(for: productIds)
        
        // 排序产品（按价格从低到高）
        products = storeProducts.sorted { 
            $0.price < $1.price 
        }
        
        productsLoaded = true
        print("✅ 成功加载 \(products.count) 个订阅产品")
    } catch {
        self.error = "加载产品失败: \(error.localizedDescription)"
        print("❌ 加载产品失败: \(error)")
    }
    
    isLoadingProducts = false
}

// 监听交易更新
func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
        // 使用 StoreKit 2 API 监听交易更新
        for await result in Transaction.updates {
            await self.handleTransactionResult(result)
        }
    }
}
```

## 处理购买流程

接下来，我们实现处理购买的功能：

```swift
// 购买产品
@MainActor
func purchase(_ product: Product) async {
    purchaseState = .inProgress
    
    do {
        // 使用 StoreKit 2 API 进行购买
        let result = try await product.purchase()
        
        // 处理购买结果
        switch result {
        case .success(let verification):
            // 验证交易
            let transaction = try checkVerified(verification)
            
            // 更新购买状态
            await updatePurchasedState(transaction: transaction)
            
            // 完成交易
            await transaction.finish()
            
            purchaseState = .purchased
            print("✅ 购买成功: \(product.id)")
            
        case .userCancelled:
            purchaseState = .notStarted
            print("⚠️ 用户取消购买")
            
        case .pending:
            purchaseState = .notStarted
            print("⏳ 购买请求等待处理")
            
        default:
            purchaseState = .notStarted
            print("❓ 未知的购买状态")
        }
    } catch {
        purchaseState = .failed(error)
        self.error = "购买失败: \(error.localizedDescription)"
        print("❌ 购买失败: \(error)")
    }
}

// 验证交易
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    // 验证购买的真实性
    switch result {
    case .unverified:
        // 处理未验证的交易
        throw StoreError.failedVerification
    case .verified(let safe):
        // 返回已验证的交易
        return safe
    }
}

// 自定义错误类型
enum StoreError: Error {
    case failedVerification
    case expiredSubscription
    case unknownError
}
```

## Apple Pay 集成

DeepSeek 应用支持 Apple Pay 作为支付选项。以下是实现 Apple Pay 支持的步骤：

### 1. 检查 Apple Pay 可用性

```swift
// 检查设备是否支持 Apple Pay
func canMakePayments() -> Bool {
    return PKPaymentAuthorizationController.canMakePayments()
}

// 检查是否支持特定的支付网络（如 Visa、MasterCard 等）
func canMakePaymentsWithNetwork() -> Bool {
    return PKPaymentAuthorizationController.canMakePayments(usingNetworks: [
        .visa, .masterCard, .chinaUnionPay, .amex
    ])
}
```

### 2. 创建 Apple Pay 按钮

在订阅界面中，我们需要添加 Apple Pay 按钮：

```swift
import SwiftUI
import PassKit

struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void
    var type: PKPaymentButtonType
    var style: PKPaymentButtonStyle
    
    init(
        type: PKPaymentButtonType = .buy,
        style: PKPaymentButtonStyle = .black,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.style = style
        self.action = action
    }
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}
```

### 3. 实现 Apple Pay 支付流程

在 `StoreKitManager` 中添加处理 Apple Pay 的方法：

```swift
// 使用 Apple Pay 进行购买
@MainActor
func purchaseWithApplePay(_ product: Product) async {
    let paymentRequest = PKPaymentRequest()
    paymentRequest.merchantIdentifier = "merchant.com.yourcompany.deepseek"
    paymentRequest.supportedNetworks = [.visa, .masterCard, .chinaUnionPay]
    paymentRequest.merchantCapabilities = .capability3DS
    paymentRequest.countryCode = "CN"
    paymentRequest.currencyCode = "CNY"
    
    // 设置支付信息
    let productPrice = NSDecimalNumber(string: "\(product.price)")
    let payment = PKPaymentSummaryItem(label: product.displayName, amount: productPrice)
    paymentRequest.paymentSummaryItems = [payment]
    
    // 显示 Apple Pay 支付界面
    let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
    controller.delegate = self  // 需实现 PKPaymentAuthorizationControllerDelegate
    
    let didPresent = await controller.present()
    if !didPresent {
        self.error = "无法显示 Apple Pay 支付界面"
        return
    }
    
    // 实际购买逻辑在代理方法中实现
}
```

注意：您需要实现 `PKPaymentAuthorizationControllerDelegate` 来处理支付结果，并将 Apple Pay 支付关联到 StoreKit 购买。

## 订阅状态管理

现在我们实现检查和更新订阅状态的功能：

```swift
// 更新已购买的产品状态
@MainActor
func updatePurchasedProducts() async {
    // 清空当前状态
    purchasedProductIDs.removeAll()
    currentSubscription = nil
    expirationDate = nil
    
    // 获取当前交易
    for await result in Transaction.currentEntitlements {
        do {
            // 验证交易
            let transaction = try checkVerified(result)
            
            // 检查是否是订阅
            if transaction.productType == .autoRenewable {
                // 检查是否过期
                if let expirationDate = transaction.expirationDate,
                   expirationDate < Date() {
                    continue
                }
                
                // 更新状态
                purchasedProductIDs.insert(transaction.productID)
                
                // 更新当前订阅信息
                if let product = MembershipProduct(rawValue: transaction.productID) {
                    currentSubscription = product
                    expirationDate = transaction.expirationDate
                }
                
                print("✅ 有效订阅: \(transaction.productID)")
            }
        } catch {
            print("❌ 验证交易失败: \(error)")
        }
    }
}

// 更新单个交易的状态
@MainActor
func updatePurchasedState(transaction: Transaction) async {
    if transaction.revocationDate == nil {
        // 添加到已购买列表
        purchasedProductIDs.insert(transaction.productID)
        
        // 更新当前订阅信息
        if let product = MembershipProduct(rawValue: transaction.productID) {
            currentSubscription = product
            expirationDate = transaction.expirationDate
        }
    } else {
        // 从已购买列表中移除
        purchasedProductIDs.remove(transaction.productID)
        
        // 如果是当前订阅被撤销，清除当前订阅信息
        if let product = MembershipProduct(rawValue: transaction.productID),
           currentSubscription == product {
            currentSubscription = nil
            expirationDate = nil
        }
    }
}

// 处理交易结果
func handleTransactionResult(_ result: VerificationResult<Transaction>) async {
    do {
        let transaction = try checkVerified(result)
        
        // 更新状态
        await updatePurchasedState(transaction: transaction)
        
        // 完成交易
        await transaction.finish()
        
        print("✅ 交易更新: \(transaction.productID)")
    } catch {
        print("❌ 处理交易失败: \(error)")
    }
}
```

## 订阅界面实现

创建订阅界面，展示产品和支付选项：

```swift
struct MembershipView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 会员特权介绍
                    MembershipBenefitsView()
                    
                    // 会员状态
                    if storeManager.isMember {
                        CurrentMembershipView()
                    }
                    
                    // 订阅产品列表
                    MembershipPlansView(selectedProduct: $selectedProduct)
                    
                    // 支付按钮
                    PaymentButtonsView(selectedProduct: selectedProduct)
                    
                    // 支付说明
                    Text("订阅条款说明")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("会员订阅")
            .navigationBarItems(trailing: Button("关闭") {
                dismiss()
            })
            .alert(item: $storeManager.error) { error in
                Alert(
                    title: Text("购买失败"),
                    message: Text(error),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
}

// 会员特权介绍视图
struct MembershipBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("会员特权")
                .font(.system(size: 24, weight: .bold))
                
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "infinity", title: "无限使用", description: "无消息数量限制")
                BenefitRow(icon: "brain", title: "高级模型", description: "优先使用最新模型")
                BenefitRow(icon: "photo", title: "图片生成", description: "支持AI图片生成")
                BenefitRow(icon: "doc", title: "文件分析", description: "支持上传文件解析")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// 会员计划选择视图
struct MembershipPlansView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @Binding var selectedProduct: Product?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("选择套餐")
                .font(.system(size: 20, weight: .bold))
            
            if storeManager.isLoadingProducts {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                ForEach(storeManager.products, id: \.id) { product in
                    PlanRow(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        action: {
                            selectedProduct = product
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// 支付按钮视图
struct PaymentButtonsView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    var selectedProduct: Product?
    
    var body: some View {
        VStack(spacing: 15) {
            // 常规购买按钮
            Button(action: {
                if let product = selectedProduct {
                    Task {
                        await storeManager.purchase(product)
                    }
                }
            }) {
                Text("订阅")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct != nil ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(selectedProduct == nil || storeManager.purchaseState == .inProgress)
            
            // Apple Pay 按钮
            if storeManager.canMakePaymentsWithNetwork() {
                ApplePayButton(type: .buy, style: .black) {
                    if let product = selectedProduct {
                        Task {
                            await storeManager.purchaseWithApplePay(product)
                        }
                    }
                }
                .frame(height: 45)
                .disabled(selectedProduct == nil || storeManager.purchaseState == .inProgress)
            }
        }
        .padding(.horizontal)
    }
}
```

## 用量限制实现

为非会员用户实现使用量限制（每日 10 条消息）：

```swift
// 在 ChatViewModel 中添加
@Published var dailyMessageCount: Int = 0
@Published var limitReached: Bool = false

// 从 UserDefaults 加载每日消息计数
private func loadDailyMessageCount() {
    // 获取当前日期的字符串表示
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let todayString = dateFormatter.string(from: Date())
    
    // 检查是否是新的一天
    let lastCountDate = UserDefaults.standard.string(forKey: "lastMessageCountDate") ?? ""
    
    if lastCountDate != todayString {
        // 新的一天，重置计数
        UserDefaults.standard.set(0, forKey: "dailyMessageCount")
        UserDefaults.standard.set(todayString, forKey: "lastMessageCountDate")
        dailyMessageCount = 0
    } else {
        // 同一天，加载现有计数
        dailyMessageCount = UserDefaults.standard.integer(forKey: "dailyMessageCount")
    }
    
    // 检查是否达到限制
    checkLimitReached()
}

// 增加消息计数
private func incrementDailyMessageCount() {
    dailyMessageCount += 1
    UserDefaults.standard.set(dailyMessageCount, forKey: "dailyMessageCount")
    
    // 检查是否达到限制
    checkLimitReached()
}

// 检查是否达到使用限制
private func checkLimitReached() {
    let isMember = membershipViewModel.isMember
    
    // 会员无限制，非会员每日10条
    limitReached = !isMember && dailyMessageCount >= freeUserDailyLimit
}

// 在发送消息前检查限制
func sendMessage(_ text: String) {
    // 检查是否达到限制
    if limitReached {
        // 显示提示并引导订阅
        showSubscriptionPrompt()
        return
    }
    
    // 正常发送消息
    // ...
    
    // 消息发送成功后增加计数
    incrementDailyMessageCount()
}

// 显示订阅提示
private func showSubscriptionPrompt() {
    let message = "您已达到今日免费使用上限（10条消息）。成为会员即可享受无限对话！"
    self.limitReachedMessage = message
    self.showingMembershipView = true
}
```

## 测试与调试

### 使用沙盒环境测试

1. 使用沙盒测试账号测试购买流程
2. 测试订阅续订和过期

```swift
// 在开发环境下输出订阅状态
#if DEBUG
func printSubscriptionStatus() {
    print("==== 订阅状态 ====")
    print("是否是会员: \(isMember)")
    if let subscription = currentSubscription {
        print("当前订阅: \(subscription.displayName)")
        if let expDate = expirationDate {
            print("到期时间: \(expDate)")
        }
    }
    print("已购买产品: \(purchasedProductIDs)")
    print("=================")
}
#endif
```

### 处理常见错误

1. 沙盒环境连接问题
2. 购买验证失败
3. Apple Pay 配置错误

```swift
// 订阅错误处理
func handleSubscriptionError(_ error: Error) {
    switch error {
    case SKError.paymentCancelled:
        self.error = "用户取消了购买"
    case SKError.paymentInvalid:
        self.error = "无效的支付信息"
    case SKError.paymentNotAllowed:
        self.error = "此设备不允许支付"
    case SKError.storeProductNotAvailable:
        self.error = "该产品在当前地区不可用"
    case SKError.cloudServiceNetworkConnectionFailed:
        self.error = "网络连接失败，请检查您的网络设置"
    default:
        self.error = "购买失败: \(error.localizedDescription)"
    }
}
```

通过本指南的两个部分，您应该能够成功实现 DeepSeek AI 应用的会员订阅功能和 Apple Pay 支付集成。如有问题，可参考 Apple 的 [StoreKit 文档](https://developer.apple.com/documentation/storekit)和[Apple Pay 文档](https://developer.apple.com/documentation/passkit/apple_pay)获取更多信息。 