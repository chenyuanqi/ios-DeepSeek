import Foundation
import Combine

class UserAPIService {
    // 基础URL
    private let baseURL = "https://api.chenyuanqi.com/api/v1"
    
    // 创建URLSession
    private let session: URLSession
    
    // 用于存储取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 模拟模式标志
    private let isMockMode: Bool
    
    init(mockMode: Bool = false) {
        self.isMockMode = mockMode
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API响应结构
    struct APIResponse<T: Decodable>: Decodable {
        let code: Int
        let message: String
        let data: T?
    }
    
    // MARK: - 用户注册
    func register(email: String, password: String, nickname: String) -> AnyPublisher<User, Error> {
        // 模拟模式直接返回模拟数据
        if isMockMode {
            return Just(User.mockUser)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/register"
        guard let url = URL(string: endpoint) else {
            return Fail(error: NSError(domain: "InvalidURL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "nickname": nickname
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🔐 发起注册请求: \(email), 昵称: \(nickname)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.networkError
                }
                
                print("📡 注册响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 409 {
                    throw AuthError.emailAlreadyInUse
                } else if httpResponse.statusCode >= 400 {
                    throw self.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: APIResponse<AuthResponse>.self, decoder: JSONDecoder())
            .tryMap { response in
                if response.code != 0 {
                    throw self.handleAPIError(code: response.code, message: response.message)
                }
                
                guard let authData = response.data else {
                    throw AuthError.unknown
                }
                
                // 保存令牌到UserDefaults
                UserDefaults.standard.set(authData.token, forKey: "userToken")
                print("✅ 注册成功: 用户ID \(authData.user.id)")
                
                return authData.user
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 用户登录
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        // 模拟模式直接返回模拟数据
        if isMockMode {
            return Just(User.mockUser)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/login"
        guard let url = URL(string: endpoint) else {
            return Fail(error: NSError(domain: "InvalidURL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🔐 发起登录请求: \(email)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.networkError
                }
                
                print("📡 登录响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    throw AuthError.invalidCredentials
                } else if httpResponse.statusCode >= 400 {
                    throw self.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: APIResponse<AuthResponse>.self, decoder: JSONDecoder())
            .tryMap { response in
                if response.code != 0 {
                    throw self.handleAPIError(code: response.code, message: response.message)
                }
                
                guard let authData = response.data else {
                    throw AuthError.unknown
                }
                
                // 保存令牌到UserDefaults
                UserDefaults.standard.set(authData.token, forKey: "userToken")
                print("✅ 登录成功: 用户ID \(authData.user.id)")
                
                return authData.user
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 获取用户信息
    func getUserInfo() -> AnyPublisher<User, Error> {
        // 模拟模式直接返回模拟数据
        if isMockMode {
            return Just(User.mockUser)
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/user"
        guard let url = URL(string: endpoint),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            return Fail(error: AuthError.unauthorized).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📱 获取用户信息")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.networkError
                }
                
                print("📡 获取用户信息响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    throw AuthError.unauthorized
                } else if httpResponse.statusCode >= 400 {
                    throw self.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: APIResponse<UserResponse>.self, decoder: JSONDecoder())
            .tryMap { response in
                if response.code != 0 {
                    throw self.handleAPIError(code: response.code, message: response.message)
                }
                
                guard let userData = response.data else {
                    throw AuthError.unknown
                }
                
                print("✅ 获取用户信息成功: \(userData.user.nickname)")
                
                return userData.user
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 退出登录
    func logout() -> AnyPublisher<Void, Error> {
        // 模拟模式直接返回成功
        if isMockMode {
            return Just(())
                .setFailureType(to: Error.self)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(baseURL)/logout"
        guard let url = URL(string: endpoint),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            return Fail(error: AuthError.unauthorized).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🚪 发起退出登录请求")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.networkError
                }
                
                print("📡 退出登录响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    throw self.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
                
                // 清除本地保存的令牌
                UserDefaults.standard.removeObject(forKey: "userToken")
                print("✅ 退出登录成功")
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 错误处理
    private func handleErrorResponse(data: Data, statusCode: Int) -> Error {
        do {
            let errorResponse = try JSONDecoder().decode(APIResponse<String?>.self, from: data)
            return self.handleAPIError(code: errorResponse.code, message: errorResponse.message)
        } catch {
            switch statusCode {
            case 400: return AuthError.invalidParameters
            case 401: return AuthError.unauthorized
            case 404: return AuthError.resourceNotFound
            case 409: return AuthError.emailAlreadyInUse
            default: return AuthError.unknown
            }
        }
    }
    
    private func handleAPIError(code: Int, message: String) -> Error {
        switch code {
        case 1001: return AuthError.invalidParameters
        case 1002: return AuthError.unauthorized
        case 1004: return AuthError.resourceNotFound
        case 1009: return AuthError.emailAlreadyInUse
        case 2000: return AuthError.serverError
        default: return NSError(domain: "APIError", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}

// MARK: - 响应结构体
extension UserAPIService {
    // 认证响应
    struct AuthResponse: Decodable {
        let user: User
        let token: String
    }
    
    // 用户响应
    struct UserResponse: Decodable {
        let user: User
    }
}

// 完善授权错误枚举
extension AuthError {
    static let networkError = AuthError(message: "网络连接错误，请检查网络后重试")
    static let serverError = AuthError(message: "服务器内部错误，请稍后重试")
    static let invalidParameters = AuthError(message: "请求参数错误")
    static let resourceNotFound = AuthError(message: "请求的资源不存在")
    static let unauthorized = AuthError(message: "未授权，请重新登录")
} 