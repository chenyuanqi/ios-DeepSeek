# DeepSeek AI 应用 - 订阅与 Apple Pay 接入指南（上）

本文档是针对初学者的详细指南，介绍如何在 DeepSeek AI 应用中实现会员订阅功能和 Apple Pay 支付。本指南基于项目现有代码，提供了从设置到实现的完整步骤。

## 目录

- [准备工作](#准备工作)
- [StoreKit 配置](#storekit-配置)
- [创建订阅产品](#创建订阅产品)
- [StoreKit 管理器实现](#storekit-管理器实现)

## 准备工作

在开始实现订阅功能前，您需要完成以下准备工作：

1. **Apple 开发者账号**：需要有有效的 Apple 开发者账号（年费 99 美元）
2. **App Store Connect 设置**：在 App Store Connect 中设置应用和 In-App Purchase 产品
3. **开发证书和 Provisioning Profile**：确保有正确的开发证书和配置文件
4. **沙盒测试账号**：在 App Store Connect 中创建沙盒测试账号用于测试购买

### 设置 App Store Connect

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)
2. App，选择您的应用（或创建一个新的应用）
3. 导航至"营利" > "订阅"
4. 订阅群组，点击"+"按钮创建新的订阅产品

## StoreKit 配置

DeepSeek 项目使用本地 StoreKit 配置文件进行开发和测试，这样可以避免每次测试都需要连接到 App Store。

### 检查项目中的 StoreKit 配置

首先，查看项目中的 `Products.storekit` 文件，这是一个本地 StoreKit 配置文件：

```swift
// DeepSeek/Products.storekit
{
  "identifier" : "...",
  "nonRenewingSubscriptions" : [

  ],
  "products" : [

  ],
  "settings" : {
    ...
  },
  "subscriptionGroups" : [
    {
      "id" : "...",
      "localizations" : [
        ...
      ],
      "name" : "DeepSeek会员",
      "subscriptions" : [
        {
          "adHocOffers" : [

          ],
          "codeOffers" : [

          ],
          "displayPrice" : "28",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "...",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "每月28元，按月计费",
              "displayName" : "月度会员",
              "locale" : "zh_CN"
            }
          ],
          "productID" : "com.deepseek.membership.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "referenceName" : "月度会员",
          "subscriptionGroupID" : "...",
          "type" : "RecurringSubscription"
        },
        // 其他订阅产品...
      ]
    }
  ],
  "version" : {
    ...
  }
}
```

### 创建或修改 StoreKit 配置

如果需要创建新的 StoreKit 配置或修改现有的配置：

1. 在 Xcode 中，选择 "File" > "New" > "File..."
2. 选择 "StoreKit Configuration File"
3. 命名为 "Products.storekit" 并保存在项目目录中
4. 或者打开现有的 `Products.storekit` 文件进行编辑

## 创建订阅产品

DeepSeek 应用提供三种订阅套餐：月度、季度和年度。现在我们将在 `Products.storekit` 文件中定义这些产品。

### 订阅产品设置

在 StoreKit 配置文件中，订阅产品定义应包含以下信息：

1. **产品 ID**：唯一标识符，如 "com.deepseek.membership.monthly"
2. **显示名称**：用户看到的名称，如 "月度会员"
3. **描述**：产品描述，如 "每月28元，按月计费"
4. **价格**：产品价格，如 "28"
5. **订阅周期**：如 "P1M"（一个月）、"P3M"（三个月）或 "P1Y"（一年）

### 示例配置

以下是三种订阅产品的示例配置：

```swift
// 月度会员
{
  "displayPrice" : "28",
  "familyShareable" : false,
  "internalID" : "5E85C815",
  "localizations" : [
    {
      "description" : "每月28元，按月计费",
      "displayName" : "月度会员",
      "locale" : "zh_CN"
    }
  ],
  "productID" : "com.deepseek.membership.monthly",
  "recurringSubscriptionPeriod" : "P1M",
  "referenceName" : "月度会员",
  "type" : "RecurringSubscription"
}

// 季度会员
{
  "displayPrice" : "78",
  "familyShareable" : false,
  "internalID" : "B731D402",
  "localizations" : [
    {
      "description" : "每季度78元，三个月有效期",
      "displayName" : "季度会员",
      "locale" : "zh_CN"
    }
  ],
  "productID" : "com.deepseek.membership.quarterly",
  "recurringSubscriptionPeriod" : "P3M",
  "referenceName" : "季度会员",
  "type" : "RecurringSubscription"
}

// 年度会员
{
  "displayPrice" : "238",
  "familyShareable" : false,
  "internalID" : "9F3E8C07",
  "localizations" : [
    {
      "description" : "每年238元，最具性价比",
      "displayName" : "年度会员",
      "locale" : "zh_CN"
    }
  ],
  "productID" : "com.deepseek.membership.yearly",
  "recurringSubscriptionPeriod" : "P1Y",
  "referenceName" : "年度会员",
  "type" : "RecurringSubscription"
}
```

## StoreKit 管理器实现

项目中的 `StoreKitManager.swift` 文件负责处理与 App Store 的通信和管理订阅。以下是实现 StoreKit 管理器的主要步骤：

### 1. 导入必要的框架

```swift
import Foundation
import StoreKit
import Combine
```

### 2. 定义订阅产品

```swift
// 订阅产品 ID 常量
enum MembershipProduct: String, CaseIterable {
    case monthly = "com.deepseek.membership.monthly"
    case quarterly = "com.deepseek.membership.quarterly"
    case yearly = "com.deepseek.membership.yearly"
    
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
    
    var period: String {
        switch self {
        case .monthly:
            return "月"
        case .quarterly:
            return "季"
        case .yearly:
            return "年"
        }
    }
}
```

### 3. 创建 StoreKit 管理器类

```swift
class StoreKitManager: ObservableObject {
    // 发布属性
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoadingProducts = false
    @Published var error: String?
    @Published var currentSubscription: MembershipProduct?
    @Published var expirationDate: Date?
    
    // 计算属性
    var isMember: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    // 购买状态
    enum PurchaseState {
        case notStarted
        case inProgress
        case purchased
        case failed(Error)
    }
    
    // 存储购买状态
    @Published var purchaseState: PurchaseState = .notStarted
    
    // 私有属性
    private var productIds = MembershipProduct.allCases.map { $0.rawValue }
    private var productsLoaded = false
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初始化时开始监听交易更新
        updateListenerTask = listenForTransactions()
        
        // 加载产品
        Task {
            await loadProducts()
        }
        
        // 检查订阅状态
        Task {
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // ... 其他方法将在后续实现 ...
}
```

这就是 StoreKit 集成的基础设置和配置。在下一部分中，我们将继续实现产品加载、购买、订阅验证和 Apple Pay 支持等功能。 