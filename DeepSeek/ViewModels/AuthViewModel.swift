import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // 用户状态
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 表单字段
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    
    // 表单模式
    @Published var isRegistrationMode = false
    
    // API服务
    private let apiService: UserAPIService
    
    // 取消令牌存储
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.apiService = UserAPIService()
        checkAuthState()
    }
    
    // 预览专用初始化方法
    init(previewMode: Bool = false) {
        if previewMode {
            // 预览模式使用模拟API服务
            self.apiService = UserAPIService(mockMode: true)
        } else {
            self.apiService = UserAPIService()
            checkAuthState()
        }
    }
    
    // 登录
    func login() {
        // 表单验证
        guard !email.isEmpty else {
            errorMessage = "请输入邮箱"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        apiService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    if let authError = error as? AuthError {
                        self?.errorMessage = authError.errorDescription
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                    print("❌ 登录失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
                self?.saveAuthState()
                self?.resetForm()
                print("✅ 登录成功: \(user.nickname)")
            })
            .store(in: &cancellables)
    }
    
    // 注册
    func register() {
        // 表单验证
        guard !username.isEmpty else {
            errorMessage = "请输入用户名"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "请输入邮箱"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return
        }
        
        // 密码强度验证
        if password.count < 8 {
            errorMessage = "密码长度不能少于8位"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        apiService.register(email: email, password: password, nickname: username)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    if let authError = error as? AuthError {
                        self?.errorMessage = authError.errorDescription
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                    print("❌ 注册失败: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
                self?.saveAuthState()
                self?.resetForm()
                print("✅ 注册成功: \(user.nickname)")
            })
            .store(in: &cancellables)
    }
    
    // 退出登录
    func logout() {
        isLoading = true
        
        apiService.logout()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    print("⚠️ 退出登录请求失败: \(error.localizedDescription)")
                }
                
                // 无论API是否成功，都执行本地退出逻辑
                self?.clearAuthState()
            }, receiveValue: { [weak self] _ in
                print("✅ 退出登录成功")
                self?.clearAuthState()
            })
            .store(in: &cancellables)
    }
    
    // 检查用户信息
    func checkAuthState() {
        // 检查UserDefaults中的登录状态
        if UserDefaults.standard.bool(forKey: "isLoggedIn"),
           let token = UserDefaults.standard.string(forKey: "userToken") {
            
            print("🔍 检测到已保存的登录信息，尝试恢复会话")
            isLoading = true
            
            // 获取用户信息
            apiService.getUserInfo()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        print("⚠️ 恢复会话失败: \(error.localizedDescription)")
                        // 清除过期会话
                        self?.clearAuthState()
                    }
                }, receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    print("✅ 恢复会话成功: \(user.nickname)")
                })
                .store(in: &cancellables)
        } else {
            print("🔍 未检测到登录信息")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // 保存认证状态
    private func saveAuthState() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        // Token已在API服务中保存
    }
    
    // 清除认证状态
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userToken")
        isAuthenticated = false
        currentUser = nil
    }
    
    // 重置表单
    func resetForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        errorMessage = nil
    }
    
    // 切换注册/登录模式
    func toggleRegistrationMode() {
        isRegistrationMode.toggle()
        resetForm()
    }
} 