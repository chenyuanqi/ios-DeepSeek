# DeepSeek AI 应用 - 订阅与 Apple Pay 实现步骤指南

本文档提供了在 DeepSeek AI 应用中实现会员订阅和 Apple Pay 支付的完整操作步骤，重点关注苹果开发者网站和 Xcode 的配置流程。

## 实现步骤总览

1. Apple 开发者账号设置
2. App Store Connect 配置
3. Xcode 项目配置
4. StoreKit 配置文件创建
5. Merchant ID 申请与配置
6. 代码实现要点
7. 测试与验证

## 第一步：Apple 开发者账号设置

1. **注册/登录 Apple 开发者账号**
   - 访问 [Apple 开发者网站](https://developer.apple.com)
   - 登录您的 Apple 开发者账号（需要支付年费 $99）
   - 确保您已经加入 Apple Developer Program

2. **创建应用 ID**
   - 在 [开发者中心](https://developer.apple.com/account/resources/identifiers/list) 选择 "Identifiers"
   - 点击 "+" 按钮创建新的 App ID
   - 选择 "App IDs" 并点击 "Continue"
   - 选择 "App" 类型并点击 "Continue"
   - 填写描述和 Bundle ID（例如：com.yourcompany.deepseek）
   - 在 Capabilities 部分，选中 "In-App Purchase" 和 "Apple Pay"
   - 点击 "Continue" 并 "Register"

## 第二步：App Store Connect 配置

1. **创建应用**
   - 登录 [App Store Connect](https://appstoreconnect.apple.com)
   - 点击 "我的 App"，然后点击 "+" 按钮创建新应用
   - 填写应用信息（名称、Bundle ID、SKU 等）

2. **配置订阅产品**
   - 在应用页面，选择 "功能" 选项卡
   - 点击 "App 内购买项目" 旁边的 "+" 按钮
   - 选择 "自动续期订阅"
   - 填写以下信息：
     * 参考名称（例如：月度会员）
     * 产品 ID（例如：com.chenyuanqi.DeepSeek.subscription.monthly）
     * 订阅组（创建新组或选择现有组）
     * 设置价格和期限（月度/季度/年度）
   - 为每个订阅产品添加本地化信息（显示名称和描述）
   - 对月度、季度和年度会员重复上述步骤
   - **注意**：产品ID必须与应用的Bundle ID保持一致，通常使用Bundle ID作为前缀，例如`com.chenyuanqi.DeepSeek.subscription.monthly`

3. **创建沙盒测试账号**
   - 在 App Store Connect 中点击 "用户和访问"
   - 选择 "沙盒" 选项卡
   - 点击 "+" 按钮创建测试账号
   - 填写邮箱、密码等信息（使用未注册过的邮箱）
   - 保存账号信息，后续测试时使用

## 第三步：Xcode 项目配置

1. **配置项目 Capabilities**
   - 打开 Xcode 项目
   - 选择项目根节点，然后选择目标应用
   - 切换到 "Signing & Capabilities" 选项卡
   - 点击 "+ Capability" 按钮
   - 添加 "In-App Purchase" 和 "Apple Pay" 功能

2. **配置 App ID**
   - 确保项目的 Bundle ID 与 Apple 开发者中心创建的 App ID 一致
   - 确保使用正确的开发者账号和团队

3. **添加必要的框架**
   - 在项目中添加 StoreKit 框架：
     * 选择项目根节点，然后选择目标应用
     * 切换到 "General" 选项卡
     * 滚动到 "Frameworks, Libraries, and Embedded Content" 部分
     * 点击 "+" 按钮，搜索并添加 StoreKit.framework
   - 如果使用 Apple Pay，添加 PassKit 框架：
     * 同样方法搜索并添加 PassKit.framework

## 第四步：StoreKit 配置文件创建

1. **创建 StoreKit 配置文件**
   - 在 Xcode 中，选择 "File" > "New" > "File..."
   - 选择 "StoreKit Configuration File"
   - 命名为 "Products.storekit" 并保存在项目目录中

2. **配置订阅产品**
   - 打开 Products.storekit 文件
   - 点击 "+" 按钮，选择 "Add Subscription Group"
   - 输入订阅组名称（例如：DeepSeek会员）
   - 在订阅组下，点击 "+" 按钮，选择 "Add Subscription"
   - 为每个订阅产品填写以下信息：
     * 参考名称（例如：月度会员）
     * 产品 ID（例如：com.chenyuanqi.DeepSeek.subscription.monthly）
     * 价格（例如：28）
     * 订阅周期（例如：1 month）
     * 添加本地化信息（显示名称和描述）
   - 为月度、季度和年度会员重复上述步骤
   - **重要**：确保StoreKit配置文件中的产品ID与App Store Connect中的完全一致

3. **启用 StoreKit 测试**
   - 选择项目根节点，然后选择目标应用
   - 切换到 "Product" 菜单 > "Scheme" > "Edit Scheme..."
   - 在左侧选择 "Run"
   - 切换到 "Options" 选项卡
   - 在 "StoreKit Configuration" 选项中，选择您创建的 Products.storekit 文件

## 第五步：Merchant ID 申请与配置（Apple Pay）

1. **创建 Merchant ID**
   - 在 [开发者中心](https://developer.apple.com/account/resources/identifiers/list) 选择 "Identifiers"
   - 点击 "+" 按钮，选择 "Merchant IDs"
   - 填写描述和标识符（例如：merchant.com.yourcompany.deepseek）
   - 点击 "Continue" 并 "Register"

2. **配置 Merchant ID**
   - 点击刚创建的 Merchant ID
   - 在 "Apple Pay Merchant Identity Certificate" 部分，点击 "Create Certificate"
   - 按照步骤生成 CSR（证书签名请求）文件
   - 上传 CSR 文件并下载生成的证书
   - 双击安装证书到 Keychain

3. **在 Xcode 中配置 Apple Pay**
   - 在 Xcode 项目的 Entitlements 文件中添加 Apple Pay 权限
   - 如果没有 Entitlements 文件，创建一个：
     * 在 Xcode 中，选择 "File" > "New" > "File..."
     * 选择 "Property List"
     * 命名为 "YourApp.entitlements"
     * 将扩展名改为 .entitlements
   - 在 Entitlements 文件中添加以下键：
     * com.apple.developer.in-app-payments
     * 值为包含您 Merchant ID 的数组：[merchant.com.yourcompany.deepseek]

## 第六步：代码实现要点

以下是实现订阅和 Apple Pay 的关键代码组件，详细代码请参考 `StoreKitManager.swift`：

1. **StoreKit 实现**
   - 创建 `StoreKitManager` 类管理所有购买和订阅
   - 实现加载产品、处理购买和验证交易的方法
   - 实现订阅状态管理和更新

2. **Apple Pay 实现**
   - 在 `Info.plist` 中添加 `NSMerchantIDs` 键，值为您的 Merchant ID 数组
   - 创建 Apple Pay 按钮和支付请求
   - 实现支付授权控制器代理方法
   - 在代码中使用正确的产品ID格式（com.chenyuanqi.DeepSeek.subscription.*）

3. **用户界面实现**
   - 创建会员订阅页面，展示产品和特权
   - 添加购买按钮和 Apple Pay 按钮
   - 实现购买状态和错误处理

## 第七步：测试与验证

1. **本地测试**
   - 运行应用，确保 StoreKit 配置已启用
   - 测试订阅流程，检查产品加载和购买功能
   - 测试 Apple Pay 支付流程

2. **沙盒环境测试**
   - 使用您创建的沙盒测试账号登录设备
   - 测试完整的购买流程
   - 测试自动续期订阅的更新

3. **常见问题排查**
   - 确保 Bundle ID 和所有配置一致
   - 检查 Merchant ID 配置
   - 验证 StoreKit 配置文件中的产品 ID 与 App Store Connect 一致（必须是com.chenyuanqi.DeepSeek.subscription.*格式）
   - 确保设备已添加有效的支付方式（对于 Apple Pay 测试）
   - 如果产品未加载，检查产品ID是否正确匹配

## 发布前的最终检查清单

1. **App Store Connect 检查**
   - 所有订阅产品状态为"已批准"
   - 设置了合适的价格和订阅条款
   - 填写了必要的税务和银行信息

2. **项目检查**
   - 移除任何测试或调试代码
   - 确保使用生产环境 API
   - 测试从沙盒转为生产环境的流程

3. **用户体验检查**
   - 订阅界面美观且易用
   - 提供清晰的订阅条款和价格信息
   - 实现订阅状态的持久化

按照以上步骤，您应该能够成功实现 DeepSeek AI 应用的会员订阅功能和 Apple Pay 支付集成。如有任何问题，请参考 Apple 官方文档或联系 Apple 开发者支持。 