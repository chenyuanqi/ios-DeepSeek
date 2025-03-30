import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 登录/注册表单
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    
    // 用于模拟存储已注册用户
    private var registeredUsers: [String: (password: String, user: User)] = [:]
    
    // 模拟登录过程
    func login() {
        isLoading = true
        errorMessage = nil
        
        // 延迟模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // 简单验证
            if self.email.isEmpty || self.password.isEmpty {
                self.errorMessage = "邮箱和密码不能为空"
                self.isLoading = false
                return
            }
            
            // 检查用户是否存在
            if let userInfo = self.registeredUsers[self.email.lowercased()], userInfo.password == self.password {
                self.currentUser = userInfo.user
                self.isAuthenticated = true
                self.saveAuthState()
            } else {
                self.errorMessage = AuthError.invalidCredentials.localizedDescription
            }
            
            self.isLoading = false
        }
    }
    
    // 模拟注册过程
    func register() {
        isLoading = true
        errorMessage = nil
        
        // 延迟模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // 表单验证
            if self.email.isEmpty || self.password.isEmpty || self.username.isEmpty {
                self.errorMessage = "所有字段都必须填写"
                self.isLoading = false
                return
            }
            
            if self.password != self.confirmPassword {
                self.errorMessage = "两次输入的密码不一致"
                self.isLoading = false
                return
            }
            
            if self.password.count < 8 {
                self.errorMessage = AuthError.weakPassword.localizedDescription
                self.isLoading = false
                return
            }
            
            // 检查邮箱是否已被注册
            if self.registeredUsers[self.email.lowercased()] != nil {
                self.errorMessage = AuthError.emailAlreadyInUse.localizedDescription
                self.isLoading = false
                return
            }
            
            // 创建新用户
            let newUser = User(email: self.email, username: self.username)
            self.registeredUsers[self.email.lowercased()] = (password: self.password, user: newUser)
            
            // 自动登录
            self.currentUser = newUser
            self.isAuthenticated = true
            self.saveAuthState()
            
            self.isLoading = false
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        clearAuthState()
    }
    
    // 检查是否有保存的登录状态
    func checkAuthState() {
        if UserDefaults.standard.bool(forKey: "isAuthenticated"),
           let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    // 保存登录状态
    private func saveAuthState() {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    // 清除登录状态
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // 表单重置
    func resetForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        errorMessage = nil
    }
} 