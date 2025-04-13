# DeepSeek AI 应用 - 项目结构说明

本文档详细介绍了 DeepSeek AI 应用的项目结构和代码组织方式，帮助开发者快速了解项目的整体架构和各个文件夹的作用。

## 目录结构

DeepSeek 项目采用标准的 iOS 应用结构，遵循 MVVM 架构模式组织代码。项目的主要目录结构如下：

```
DeepSeek/
├── DeepSeek.xcodeproj/            # Xcode 项目文件
├── DeepSeek/                       # 主应用源代码
│   ├── Models/                     # 数据模型
│   ├── Views/                      # 用户界面
│   ├── ViewModels/                 # 视图模型
│   ├── Services/                   # 网络服务和业务逻辑
│   ├── Extension/                  # Swift 扩展
│   ├── Assets.xcassets/            # 图片和颜色资源
│   ├── Preview Content/            # SwiftUI 预览资源
│   ├── DeepSeekApp.swift           # 应用入口
│   ├── ContentView.swift           # 主内容视图
│   ├── AppDelegate.swift           # 应用代理
│   ├── Products.storekit           # StoreKit 内购配置
│   ├── DeepSeek.entitlements       # 应用权限配置
│   ├── Info.plist.append           # 附加信息配置
│   └── NetworkConfig.plist         # 网络配置文件
├── DeepSeekTests/                  # 单元测试
└── DeepSeekUITests/                # UI 测试
```

## 核心组件详解

### Models 目录

包含应用的数据结构和领域模型：

- `User.swift` - 用户模型和认证错误类型
- `Message.swift` - 消息和对话数据结构

### Views 目录

包含所有 SwiftUI 视图和界面组件：

- `LoginView.swift` - 登录和注册界面
- `ChatView.swift` - 主聊天界面
- `ChatHistoryView.swift` - 聊天历史记录界面
- `MembershipView.swift` - 会员订阅界面
- `ThemeSettingsView.swift` - 主题设置界面
- `ProfileEditView.swift` - 个人资料编辑界面

### ViewModels 目录

包含视图模型，处理业务逻辑和数据绑定：

- `AuthViewModel.swift` - 管理用户认证状态
- `ChatViewModel.swift` - 管理聊天和历史记录
- `MembershipViewModel.swift` - 管理会员订阅
- `ThemeManager.swift` - 管理应用主题设置

### Services 目录

处理网络请求和外部服务集成：

- `APIService.swift` - 处理与 DeepSeek API 的通信
- `UserAPIService.swift` - 处理用户认证和个人资料 API
- `StoreKitManager.swift` - 管理 App Store 内购

### Extension 目录

包含 Swift 类的扩展和辅助功能：

- `InfoPlist.swift` - 应用配置文件扩展

## 项目架构

### MVVM 架构

项目采用 MVVM（Model-View-ViewModel）架构模式：

1. **Model** - 表示应用数据和业务逻辑
2. **View** - 定义用户界面和视觉元素
3. **ViewModel** - 作为 View 和 Model 之间的桥梁，处理 UI 逻辑

### 数据流

应用使用 Combine 框架实现响应式数据流：

```
User Action → ViewModel → Service → API → ViewModel → View
```

### 模块间通信

模块间通信使用以下方式：

1. **Combine Publishers** - 在异步操作中传递数据
2. **@Published 属性** - 发布状态变化
3. **@EnvironmentObject** - 在视图层次结构间共享视图模型
4. **Delegates** - 在特定情况下使用委托模式

## 核心文件详解

### DeepSeekApp.swift

应用的入口点，定义应用生命周期和主要依赖项：

```swift
@main
struct DeepSeekApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var membershipViewModel = MembershipViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            // 渲染主内容或登录视图，取决于认证状态
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authViewModel)
            .environmentObject(themeManager)
            .environmentObject(membershipViewModel)
            .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
```

### ContentView.swift

应用的主内容容器：

```swift
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // 显示聊天界面
        ChatView()
    }
}
```

### AppDelegate.swift

应用代理，处理应用级事件和通知：

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 应用启动时的初始化代码
        return true
    }
}
```

## 关键技术和框架

项目使用了多种现代 iOS 开发技术：

1. **SwiftUI** - 构建用户界面
2. **Combine** - 处理异步事件和数据流
3. **MarkdownUI** - 渲染 Markdown 格式内容
4. **StoreKit** - 处理应用内购买
5. **UserDefaults** - 存储用户首选项和认证信息
6. **URLSession** - 处理网络请求

## 开发规范

### 命名约定

- 类型名称使用 PascalCase（如 `ChatViewModel`）
- 变量和函数名称使用 camelCase（如 `sendMessage`）
- 常量使用 camelCase 或全大写下划线分隔（如 `baseURL` 或 `API_KEY`）

### 代码组织

每个文件通常遵循以下结构：

1. 导入语句
2. 协议/类/结构体声明
3. 属性
4. 初始化方法
5. 公共方法
6. 私有方法
7. 扩展

### 注释规范

使用清晰简洁的注释说明代码功能：

```swift
// MARK: - 生命周期方法

// MARK: - 公共方法

// MARK: - 私有辅助方法

// TODO: 需要完成的工作

// FIXME: 需要修复的问题

/// 文档注释，描述方法功能
/// - Parameters:
///   - param1: 参数1说明
///   - param2: 参数2说明
/// - Returns: 返回值说明
/// - Throws: 可能抛出的错误
```

## 开发工作流程

开发新功能时的一般工作流程：

1. 在 Models 目录中定义新的数据模型（如果需要）
2. 在 Services 目录中实现相关 API 调用
3. 在 ViewModels 目录中添加业务逻辑
4. 在 Views 目录中创建用户界面
5. 在 DeepSeekApp.swift 中注入新的依赖（如果需要）

## 测试策略

项目包含以下测试类型：

1. **单元测试** - 在 DeepSeekTests 目录中
2. **UI 测试** - 在 DeepSeekUITests 目录中
3. **预览测试** - 使用 SwiftUI Previews 进行快速视觉测试

## 资源管理

### Assets.xcassets

包含所有图像资源和颜色：

- 应用图标
- 按钮图标
- 适应深色/浅色模式的颜色

### 配置文件

- Info.plist - 基本应用配置
- NetworkConfig.plist - API 端点和网络配置
- Products.storekit - 内购商品定义 