# Apple Pay 沙盒测试修复指南

当您在 Xcode 模拟器中测试 Apple Pay 功能时，如果遇到以下提示：

```
Sign in with Apple Account
Press "OK" to simulate authenticating
with an Apple Account.
[Environment:Xcode]
```

这表明您需要配置沙盒测试环境。以下是完整的修复步骤：

## 步骤一：确保正确配置 Info.plist

1. 打开项目中的 `Info.plist` 文件
2. 添加以下键值：

```xml
<key>NSMerchantIDs</key>
<array>
    <string>merchant.com.chenyuanqi.DeepSeek</string>
</array>
```

## 步骤二：更新 StoreKitManager 中的 Merchant ID

确保 `StoreKitManager.swift` 文件中的 Merchant ID 与 Info.plist 中配置的完全一致：

```swift
paymentRequest.merchantIdentifier = "merchant.com.chenyuanqi.DeepSeek"
```

## 步骤三：配置 Xcode 沙盒测试账号

1. 在模拟器或设备上运行应用前，配置沙盒测试账号：
   - 打开 `Xcode` > `Preferences` (或 `Settings`) > `Accounts`
   - 确保您已登录开发者账号
   - 如果使用模拟器，确保 StoreKit 配置文件正确设置

2. 编辑运行方案（Run Scheme）：
   - 选择 `Product` > `Scheme` > `Edit Scheme...`
   - 选择 `Run` > `Options` 选项卡
   - 确保已选择 `StoreKit Configuration` 文件（通常是 `Products.storekit`）

## 步骤四：配置沙盒测试账号

测试 Apple Pay 时需要正确设置沙盒测试账号：

1. 在项目运行时，当出现 Apple Pay 授权提示时，点击 `OK`
2. 如果要测试不同的支付场景，可以在苹果开发者网站配置多个沙盒测试账号:
   - 登录 [App Store Connect](https://appstoreconnect.apple.com)
   - 导航到 `用户和访问` > `沙盒技术人员`
   - 按需添加和配置测试账号

## 步骤五：Xcode 中简化测试流程

为了便于在 Xcode 模拟器中测试，可以添加以下代码到 `StoreKitManager` 类中：

```swift
#if DEBUG
// 处理模拟器中的 Apple Pay 测试
extension StoreKitManager {
    // 在模拟器中模拟 Apple Pay 支付完成
    func simulateApplePayCompletion(for product: Product) async -> Transaction? {
        do {
            // 模拟器中直接使用 StoreKit 购买
            return try await purchase(product)
        } catch {
            self.error = "模拟支付失败: \(error.localizedDescription)"
            return nil
        }
    }
}
#endif
```

## 常见错误排查

如果测试时仍然遇到问题，请检查以下几点：

1. **Merchant ID 一致性**：确保所有地方使用的 Merchant ID 完全一致
2. **沙盒账号配置**：确认已正确配置沙盒测试账号
3. **StoreKit 配置文件**：确认已启用 StoreKit 配置文件
4. **模拟器版本**：尝试使用不同版本的 iOS 模拟器测试
5. **清除模拟器数据**：重置模拟器以清除任何潜在的缓存问题
6. **日志检查**：在控制台中查找与支付相关的错误信息

按照以上步骤配置后，您应该能够在 Xcode 模拟器中成功测试 Apple Pay 功能。 