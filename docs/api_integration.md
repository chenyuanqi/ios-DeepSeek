# DeepSeek AI 应用 - API 集成文档

本文档详细介绍了 DeepSeek AI 应用如何集成和使用 DeepSeek API 进行聊天功能的实现，包括标准请求和流式响应的处理。

## 目录

- [API 概述](#api-概述)
- [数据模型](#数据模型)
- [API 服务实现](#api-服务实现)
  - [标准请求](#标准请求)
  - [流式响应](#流式响应)
- [模型切换](#模型切换)
- [错误处理](#错误处理)
- [调试与日志](#调试与日志)
- [开发者指南](#开发者指南)

## API 概述

DeepSeek AI 应用使用官方的 DeepSeek API 进行通信，支持以下功能：

- 标准请求：发送单次请求并获取完整响应
- 流式响应：实时接收和显示 AI 回复，提供打字机效果
- 模型切换：支持在 DeepSeek-V3 和 DeepSeek-R1 模型之间切换

API 通信通过 `APIService.swift` 类实现，使用 Swift 的 Combine 框架进行异步数据处理。

## 数据模型

### 请求模型

```swift
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool
    let max_tokens: Int?
    let temperature: Double?
    let top_p: Double?
    let top_k: Int?
    let frequency_penalty: Double?
    let n: Int?
    let response_format: ResponseFormat?
    
    struct ResponseFormat: Codable {
        let type: String
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
```

### 响应模型

标准响应：

```swift
struct ChatCompletionResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int?
        let message: ChatMessage?
        let finish_reason: String?
    }
    
    struct Usage: Codable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }
}
```

流式响应：

```swift
struct ChatCompletionChunk: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?
    
    struct Choice: Codable {
        let index: Int?
        let delta: Delta?
        let finish_reason: String?
    }
    
    struct Delta: Codable {
        let role: String?
        let content: String?
    }
}
```

### DeepSeek 模型

```swift
enum DeepSeekModel: String, CaseIterable {
    case v3 = "deepseek-ai/DeepSeek-V3"
    case r1 = "deepseek-ai/DeepSeek-R1"
    
    var displayName: String {
        switch self {
        case .v3:
            return "DeepSeek-V3"
        case .r1:
            return "DeepSeek-R1"
        }
    }
    
    var description: String {
        switch self {
        case .v3:
            return "通用智能助手"
        case .r1:
            return "深度思考模式"
        }
    }
}
```

## API 服务实现

`APIService` 类负责处理与 DeepSeek API 的所有通信：

```swift
class APIService {
    // API 配置
    private let apiKey = "sk-xxxxxxxxxxxx"
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    
    // 当前选择的模型
    private var currentModel: DeepSeekModel = .v3
    
    // URLSession 实例
    private let session: URLSession
    
    init() {
        // 配置 URLSession
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        
        // 添加默认的 HTTP 头
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer sk-xxxxxxxxxxxx"
        ]
        
        self.session = URLSession(configuration: config)
    }
    
    // 设置当前模型
    func setModel(_ model: DeepSeekModel)
    
    // 获取当前模型
    func getCurrentModel() -> DeepSeekModel
    
    // API 请求方法
    func sendMessage(_ messages: [Message]) -> AnyPublisher<String, APIError>
    func sendMessageStream(_ messages: [Message]) -> PassthroughSubject<String, APIError>
}
```

### 标准请求

标准请求实现使用 Combine 的 `AnyPublisher` 返回完整响应：

```swift
func sendMessage(_ messages: [Message]) -> AnyPublisher<String, APIError> {
    guard let url = URL(string: baseURL) else {
        return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
    }
    
    // 将 Message 转换为 ChatMessage
    let chatMessages = messages.map { message in
        ChatMessage(
            role: message.isUser ? "user" : "assistant",
            content: message.content
        )
    }
    
    // 创建请求体
    let requestBody = ChatCompletionRequest(
        model: currentModel.rawValue,
        messages: chatMessages,
        stream: false,
        max_tokens: 2048,
        temperature: 0.7,
        top_p: 0.7,
        top_k: 50,
        frequency_penalty: 0.5,
        n: 1,
        response_format: ChatCompletionRequest.ResponseFormat(type: "text")
    )
    
    // 构建请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try? JSONEncoder().encode(requestBody)
    
    // 发送请求并处理响应
    return session.dataTaskPublisher(for: request)
        .tryMap { data, response in
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // 检查状态码
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw APIError.unauthorized
            case 429:
                throw APIError.rateLimited
            default:
                throw APIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }
        .decode(type: ChatCompletionResponse.self, decoder: JSONDecoder())
        .mapError { error in
            // 转换错误类型
            if let apiError = error as? APIError {
                return apiError
            } else if error is DecodingError {
                return APIError.decodingFailed(error)
            } else {
                return APIError.requestFailed(error)
            }
        }
        .map { response in
            // 提取并返回响应内容
            guard let choice = response.choices?.first,
                  let message = choice.message,
                  !message.content.isEmpty else {
                return "抱歉，我无法生成回复。"
            }
            return message.content
        }
        .eraseToAnyPublisher()
}
```

### 流式响应

流式响应使用自定义的 `PassthroughSubject` 实现增量更新：

```swift
func sendMessageStream(_ messages: [Message]) -> PassthroughSubject<String, APIError> {
    let subject = PassthroughSubject<String, APIError>()
    
    guard let url = URL(string: baseURL) else {
        subject.send(completion: .failure(.invalidURL))
        return subject
    }
    
    // 将 Message 转换为 ChatMessage
    let chatMessages = messages.map { message in
        ChatMessage(
            role: message.isUser ? "user" : "assistant",
            content: message.content
        )
    }
    
    // 创建请求体（使用流式选项）
    let requestBody = ChatCompletionRequest(
        model: currentModel.rawValue,
        messages: chatMessages,
        stream: true,  // 启用流式响应
        max_tokens: 2048,
        temperature: 0.7,
        top_p: 0.7,
        top_k: 50,
        frequency_penalty: 0.5,
        n: 1,
        response_format: ChatCompletionRequest.ResponseFormat(type: "text")
    )
    
    // 构建请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = try? JSONEncoder().encode(requestBody)
    
    // 创建数据任务
    let task = session.dataTask(with: request) { data, response, error in
        // 处理错误
        if let error = error {
            subject.send(completion: .failure(.requestFailed(error)))
            return
        }
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            subject.send(completion: .failure(.invalidResponse))
            return
        }
        
        // 检查状态码
        switch httpResponse.statusCode {
        case 200...299:
            break // 继续处理
        case 401:
            subject.send(completion: .failure(.unauthorized))
            return
        case 429:
            subject.send(completion: .failure(.rateLimited))
            return
        default:
            subject.send(completion: .failure(.apiError("HTTP \(httpResponse.statusCode)")))
            return
        }
        
        // 处理流式数据
        guard let data = data else {
            subject.send(completion: .failure(.invalidResponse))
            return
        }
        
        // 按行分割数据并解析
        let responseString = String(decoding: data, as: UTF8.self)
        let lines = responseString.components(separatedBy: "\n\n")
        
        for line in lines where !line.isEmpty {
            // 移除 "data: " 前缀
            let dataPrefix = "data: "
            if line.hasPrefix(dataPrefix) {
                let jsonString = String(line.dropFirst(dataPrefix.count))
                
                // 检查结束信号
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                    subject.send(completion: .finished)
                    return
                }
                
                // 解析 JSON
                do {
                    let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: jsonString.data(using: .utf8)!)
                    
                    // 提取增量内容
                    if let choice = chunk.choices?.first,
                       let content = choice.delta?.content,
                       !content.isEmpty {
                        subject.send(content)
                    }
                } catch {
                    print("解析流式数据错误: \(error)")
                }
            }
        }
        
        // 完成流式传输
        subject.send(completion: .finished)
    }
    
    // 启动任务
    task.resume()
    
    return subject
}
```

## 模型切换

应用支持在 DeepSeek-V3（标准模式）和 DeepSeek-R1（深度思考模式）之间切换：

```swift
// APIService 中的模型切换方法
func setModel(_ model: DeepSeekModel) {
    self.currentModel = model
    print("已切换到模型: \(model.displayName) - \(model.description)")
}

// ChatViewModel 中的模型切换方法
func toggleDeepThinking(_ enabled: Bool) {
    isDeepThinkingEnabled = enabled
    
    // 根据当前模式设置模型
    if enabled {
        apiService.setModel(.r1)  // 切换到 DeepSeek-R1 模型
        print("🧠 已切换到深度思考模式: DeepSeek-R1")
    } else {
        apiService.setModel(.v3)  // 切换回默认的 DeepSeek-V3 模型
        print("🧠 已切换到标准模式: DeepSeek-V3")
    }
}
```

## 错误处理

API 错误通过自定义的 `APIError` 枚举处理：

```swift
enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case apiError(String)
    case unauthorized
    case rateLimited
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .decodingFailed(let error):
            return "解析响应失败: \(error.localizedDescription)"
        case .apiError(let message):
            return "API错误: \(message)"
        case .unauthorized:
            return "API授权失败，请检查API密钥"
        case .rateLimited:
            return "超出API请求限制，请稍后再试"
        case .networkError:
            return "网络连接错误，请检查网络设置"
        }
    }
}
```

## 调试与日志

应用实现了详细的日志记录，跟踪API请求和响应：

```swift
// 记录请求开始
print("🚀 开始API请求: \(currentModel.displayName)")
print("📦 请求体大小: \(request.httpBody?.count ?? 0) 字节")

// 记录网络连接状态
print("🔌 网络状态: \(error?.localizedDescription ?? "连接成功")")

// 记录HTTP响应
print("📫 收到HTTP响应: \(httpResponse.statusCode)")
print("📏 响应大小: \(data.count) 字节")

// 记录数据解析
print("🔍 解析响应数据...")
print("✅ 解析成功: \(response.choices?.count ?? 0) 个选择项")

// 记录流式数据
print("📲 收到流式数据块: \(content.prefix(20))...")
```

## 开发者指南

### 配置 API 密钥

在使用前，需要设置您的 DeepSeek API 密钥：

1. 在 `APIService.swift` 中替换示例 API 密钥
2. 建议将密钥存储在安全的位置，如 Keychain 或环境变量

```swift
// 更安全的 API 密钥存储方式
private var apiKey: String {
    // 从 Keychain 获取密钥
    if let key = KeychainService.shared.get(key: "deepseek_api_key") {
        return key
    }
    
    // 从环境变量或配置文件获取
    if let key = Bundle.main.infoDictionary?["DEEPSEEK_API_KEY"] as? String {
        return key
    }
    
    fatalError("未找到 API 密钥")
}
```

### 自定义 API 参数

可以根据需要调整请求参数：

```swift
// 创建自定义参数的请求
let requestBody = ChatCompletionRequest(
    model: currentModel.rawValue,
    messages: chatMessages,
    stream: true,
    max_tokens: 4096,  // 增加最大令牌数
    temperature: 0.9,  // 提高创造性
    top_p: 0.95,       // 调整采样阈值
    top_k: 100,        // 调整采样候选数
    frequency_penalty: 0.7,  // 增加词汇多样性
    n: 1,
    response_format: ChatCompletionRequest.ResponseFormat(type: "text")
)
```

### 扩展 API 功能

要添加新的 API 功能，例如分析消息重要性或生成摘要：

```swift
// 分析消息重要性
func analyzeImportance(message: Message) -> AnyPublisher<Int, APIError> {
    // 实现分析逻辑，返回1-10的重要性评分
}

// 生成对话摘要
func generateSummary(for messages: [Message], range: ClosedRange<Int>) -> AnyPublisher<ConversationSummary, APIError> {
    // 实现摘要生成逻辑
}
```

### 调试模式

在开发环境中，可以启用模拟模式，无需真实 API 调用：

```swift
// 模拟 API 响应（用于开发测试）
func mockStreamResponse(_ messages: [Message]) -> PassthroughSubject<String, APIError> {
    let subject = PassthroughSubject<String, APIError>()
    
    // 模拟延迟和增量响应
    DispatchQueue.global().async {
        // 模拟思考时间
        Thread.sleep(forTimeInterval: 1.0)
        
        // 生成模拟回复
        let response = "这是一个模拟的API响应，用于测试流式显示功能。"
        
        // 逐字发送
        for char in response {
            Thread.sleep(forTimeInterval: 0.05)
            subject.send(String(char))
        }
        
        subject.send(completion: .finished)
    }
    
    return subject
}
``` 