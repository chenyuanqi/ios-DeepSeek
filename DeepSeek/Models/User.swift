import Foundation

// 用户模型
struct User: Identifiable, Codable {
    let id: Int
    let email: String?
    let nickname: String
    let avatar: String?
    let signature: String?
    let created_at: String
    let updated_at: String
    
    // 方便访问的属性
    var username: String {
        return nickname
    }
    
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        return URL(string: avatar)
    }
    
    var formattedCreatedDate: String {
        // 将ISO 8601日期字符串转换为更友好的格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        guard let date = dateFormatter.date(from: created_at) else {
            return "未知时间"
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy年MM月dd日"
        outputFormatter.locale = Locale(identifier: "zh_CN")
        
        return outputFormatter.string(from: date)
    }
    
    // 提供预览用的模拟数据
    static var mockUser: User {
        return User(
            id: 1,
            email: "user@example.com",
            nickname: "测试用户",
            avatar: "https://via.placeholder.com/150",
            signature: "这是一个测试签名",
            created_at: "2023-03-27T08:00:00Z",
            updated_at: "2023-03-27T08:00:00Z"
        )
    }
}

// 认证错误枚举
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
