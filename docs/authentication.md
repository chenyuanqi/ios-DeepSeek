# DeepSeek AI 应用 - 认证功能实现文档

本文档详细介绍了 DeepSeek AI 应用中用户认证系统的实现方式，包括注册、登录、个人资料管理等功能，帮助开发者快速了解项目的认证流程。

## 目录

- [DeepSeek AI 应用 - 认证功能实现文档](#deepseek-ai-应用---认证功能实现文档)
  - [目录](#目录)
  - [架构概述](#架构概述)
  - [认证流程](#认证流程)
    - [注册流程](#注册流程)
    - [登录流程](#登录流程)
    - [登出流程](#登出流程)
  - [实现细节](#实现细节)
    - [模型层](#模型层)
    - [视图模型层](#视图模型层)
    - [视图层](#视图层)
    - [网络服务层](#网络服务层)
  - [数据存储](#数据存储)
  - [会话管理](#会话管理)
  - [开发者指南](#开发者指南)
    - [添加新的认证功能](#添加新的认证功能)
    - [调试模式](#调试模式)
    - [安全性考虑](#安全性考虑)
    - [自定义登录界面](#自定义登录界面)

## 架构概述

认证系统遵循 MVVM (Model-View-ViewModel) 架构模式：

- **模型(Model)**: 定义在 `User.swift` 中，包含用户数据结构和认证错误类型
- **视图(View)**: 定义在 `LoginView.swift` 中，负责 UI 展示
- **视图模型(ViewModel)**: 定义在 `AuthViewModel.swift` 中，处理认证业务逻辑
- **服务(Service)**: 定义在 `UserAPIService.swift` 中，处理与后端 API 的通信

## 认证流程

### 注册流程

1. 用户输入邮箱、用户名和密码
2. 前端进行表单验证
3. 调用 `register()` 方法向后端 API 发送注册请求
4. 处理注册响应，成功则自动登录，失败则显示错误信息

### 登录流程

1. 用户输入邮箱和密码
2. 调用 `login()` 方法向后端 API 发送登录请求
3. 接收包含认证令牌的响应
4. 存储令牌和用户信息
5. 更新应用状态为已登录

### 登出流程

1. 调用 `logout()` 方法
2. 清除本地存储的令牌和用户信息
3. 更新应用状态为未登录

## 实现细节

### 模型层

**User 模型** (`User.swift`)：

```swift
struct User: Identifiable, Codable {
    let id: Int
    let email: String?
    let nickname: String
    let avatar: String?
    let signature: String?
    let created_at: String
    let updated_at: String
    
    // 便捷属性
    var username: String {
        return nickname
    }
    
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        return URL(string: avatar)
    }
}

// 认证错误类型
struct AuthError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
    
    static let invalidCredentials = AuthError(message: "邮箱或密码错误")
    static let emailAlreadyInUse = AuthError(message: "该邮箱已被注册")
    static let weakPassword = AuthError(message: "密码强度不足，请使用包含字母和数字的组合")
    static let unknown = AuthError(message: "发生未知错误，请稍后重试")
}
```

### 视图模型层

**认证视图模型** (`AuthViewModel.swift`)：

```swift
class AuthViewModel: ObservableObject {
    // 发布属性
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistrationMode = false
    
    // 表单字段
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    
    // 服务依赖
    private let userAPIService = UserAPIService()
    private var cancellables = Set<AnyCancellable>()
    
    // 主要方法
    func login()
    func register()
    func logout()
    func checkAuthStatus()
    func updateUserProfile(nickname: String)
}
```

### 视图层

**登录视图** (`LoginView.swift`)：

```swift
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isSecured: Bool = true
    @State private var isConfirmSecured: Bool = true
    
    var body: some View {
        // 登录表单界面实现
    }
}

// 表单字段组件
struct FormField: View { ... }

// 密码字段组件
struct PasswordField: View { ... }
```

**个人资料编辑视图** (`ProfileEditView.swift`)：

```swift
struct ProfileEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var nickname: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        // 个人资料编辑界面实现
    }
}
```

### 网络服务层

**用户API服务** (`UserAPIService.swift`)：

```swift
class UserAPIService {
    // API 端点
    private let baseURL = "https://api.example.com/"
    private let loginPath = "login"
    private let registerPath = "register"
    private let profilePath = "profile"
    
    // 主要方法
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error>
    func register(email: String, password: String, username: String) -> AnyPublisher<AuthResponse, Error>
    func fetchUserProfile() -> AnyPublisher<User, Error>
    func updateUserProfile(nickname: String) -> AnyPublisher<User, Error>
    
    // 辅助方法
    private func createRequest(...) -> URLRequest
    private func handleResponse<T: Decodable>(...) -> AnyPublisher<T, Error>
}
```

## 数据存储

认证信息使用 `UserDefaults` 安全存储：

```swift
// 保存令牌和用户信息
func saveAuthData(token: String, user: User) {
    UserDefaults.standard.set(token, forKey: "authToken")
    
    if let encodedUser = try? JSONEncoder().encode(user) {
        UserDefaults.standard.set(encodedUser, forKey: "currentUser")
    }
}

// 读取令牌和用户信息
func loadAuthData() -> (token: String?, user: User?) {
    let token = UserDefaults.standard.string(forKey: "authToken")
    
    var user: User?
    if let userData = UserDefaults.standard.data(forKey: "currentUser") {
        user = try? JSONDecoder().decode(User.self, from: userData)
    }
    
    return (token, user)
}

// 清除认证数据
func clearAuthData() {
    UserDefaults.standard.removeObject(forKey: "authToken")
    UserDefaults.standard.removeObject(forKey: "currentUser")
}
```

## 会话管理

应用启动时会自动检查认证状态，恢复用户会话：

```swift
func checkAuthStatus() {
    // 从本地存储加载认证数据
    let (token, user) = loadAuthData()
    
    // 如果有令牌和用户信息
    if let token = token, let user = user {
        // 更新认证状态
        self.currentUser = user
        self.isAuthenticated = true
        
        // 验证令牌有效性
        validateToken(token)
    } else {
        // 没有认证信息
        self.isAuthenticated = false
        self.currentUser = nil
    }
}

private func validateToken(_ token: String) {
    // 向后端发送请求验证令牌有效性
    // 如果无效，则调用 logout()
}
```

## 开发者指南

### 添加新的认证功能

如果需要添加新的认证相关功能（如密码重置、双因素认证等），建议按照以下步骤：

1. 在 `UserAPIService.swift` 中添加相应的 API 调用方法
2. 在 `AuthViewModel.swift` 中添加业务逻辑方法
3. 创建新的视图或在现有视图中添加相应的 UI 组件

### 调试模式

在开发环境中，可以使用模拟数据进行测试：

```swift
// 在 AuthViewModel 中初始化为预览模式
init(previewMode: Bool = false) {
    if previewMode {
        self.currentUser = User.mockUser
        self.isAuthenticated = true
    } else {
        checkAuthStatus()
    }
}
```

### 安全性考虑

- 请勿在客户端硬编码敏感信息，如API密钥
- 确保令牌安全存储，考虑使用 Keychain 代替 UserDefaults
- 实现令牌过期后的自动刷新机制
- 添加请求频率限制和防暴力破解机制

### 自定义登录界面

登录界面支持主题定制，可以通过 `ThemeManager` 调整颜色和样式：

```swift
// 在 LoginView 中使用主题颜色
Text("DeepSeek")
    .font(.system(size: 28, weight: .bold))
    .foregroundColor(Color("AdaptiveText"))
``` 