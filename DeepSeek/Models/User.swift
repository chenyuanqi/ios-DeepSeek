import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    var username: String
    
    init(id: UUID = UUID(), email: String, username: String) {
        self.id = id
        self.email = email
        self.username = username
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "邮箱或密码不正确"
        case .emailAlreadyInUse:
            return "该邮箱已被注册"
        case .weakPassword:
            return "密码强度不足，请使用至少8位包含数字和字母的密码"
        case .networkError:
            return "网络连接错误，请检查网络后重试"
        case .unknown:
            return "发生未知错误，请稍后重试"
        }
    }
} 