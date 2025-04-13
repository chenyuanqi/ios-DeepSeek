# DeepSeek AI 应用 - 产品ID修复指南

经检查，当前项目中存在产品ID不一致的问题。产品ID应该使用统一的格式 `com.chenyuanqi.DeepSeek.subscription.*`，但目前在不同文件中使用了不同的格式。本文档将指导您如何修复这些不一致问题。

## 问题概述

当前项目中，产品ID格式存在以下不一致：

1. 在 `StoreKitManager.swift` 中使用的是 `com.deepseek.app.subscription.*` 格式
2. 在 `Products.storekit` 中使用的是 `com.deepseek.membership.*` 格式
3. 文档中使用的是 `com.yourcompany.deepseek.*` 格式（已更新）

正确的格式应该是 `com.chenyuanqi.DeepSeek.subscription.*`。

## 修复步骤

### 1. 修改 StoreKit 配置文件

1. 打开 `DeepSeek/Products.storekit` 文件
2. 修改所有产品ID，使用以下格式：
   - 月度会员：`com.chenyuanqi.DeepSeek.subscription.monthly`
   - 季度会员：`com.chenyuanqi.DeepSeek.subscription.quarterly`
   - 年度会员：`com.chenyuanqi.DeepSeek.subscription.yearly`

### 2. 修改 StoreKitManager.swift 文件

1. 打开 `DeepSeek/Services/StoreKitManager.swift` 文件
2. 找到 `enum ProductID` 定义，更新产品ID：

```swift
enum ProductID: String, CaseIterable {
    case monthlySubscription = "com.chenyuanqi.DeepSeek.subscription.monthly"
    case quarterlySubscription = "com.chenyuanqi.DeepSeek.subscription.quarterly"
    case yearlySubscription = "com.chenyuanqi.DeepSeek.subscription.yearly"
    
    // 其他代码保持不变...
}
```

### 3. 检查其他引用

1. 确保项目中其他地方没有硬编码引用这些产品ID
2. 特别检查以下文件：
   - `MembershipViewModel.swift`
   - `MembershipView.swift`
   - 任何处理订阅的测试文件

### 4. 更新 App Store Connect 配置

如果您已经在 App Store Connect 中创建了这些产品，您需要:

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 导航到您的应用 > "功能" > "App 内购买项目"
3. 如果已存在不正确ID的产品，可能需要删除它们并创建新的产品
4. 创建新产品时，使用正确的产品ID格式：`com.chenyuanqi.DeepSeek.subscription.*`

### 5. 重新生成 StoreKit 配置文件（可选）

如果您希望完全重新开始，可以：

1. 删除现有的 `Products.storekit` 文件
2. 创建新的配置文件：File > New > File... > StoreKit Configuration File
3. 按照 [订阅与 Apple Pay 步骤指南](./subscription_step_by_step.md) 中的说明配置产品，确保使用正确的ID格式

## 测试与验证

修改完成后，请按照以下步骤验证更改：

1. **运行应用**，确保产品能够正确加载
2. 使用 StoreKit 测试功能验证购买流程
3. 检查控制台日志，确保没有与产品ID相关的错误

## 注意事项

1. **Bundle ID 一致性**：确保产品ID的前缀与应用的Bundle ID一致（应为`com.chenyuanqi.DeepSeek`）
2. **大小写敏感**：注意产品ID中的大小写，特别是`DeepSeek`部分应该保持一致
3. **订阅组**：如果您在App Store Connect中创建了订阅组，可能需要更新订阅组的ID

产品ID格式一致性对于应用内购买功能的正常工作至关重要。修复这些不一致问题将确保订阅功能在所有环境中（开发、测试和生产）正常运行。 