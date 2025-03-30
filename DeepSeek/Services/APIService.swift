import Foundation
import Combine

struct ChatMessage: Codable {
    let role: String
    let content: String
}

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

// 流式响应数据结构
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

// 定义DeepSeek支持的模型
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

class APIService {
    // 使用你的API密钥
    private let apiKey = "sk-klteickhnwvgbkmdwhtbpajgphsvnppqcpxlbxdvrdgylgdh"
    private let baseURL = "https://api.siliconflow.cn/v1/chat/completions"
    
    // 默认模型和当前选择的模型
    private var currentModel: DeepSeekModel = .v3
    
    // 共享URLSession实例，应用于所有请求
    private let session: URLSession
    
    init() {
        // 创建自定义配置的URLSession
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60 // 60秒超时
        config.timeoutIntervalForResource = 120 // 120秒资源超时
        
        // 添加默认的HTTP头，减少每次请求时的重复设置
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer sk-klteickhnwvgbkmdwhtbpajgphsvnppqcpxlbxdvrdgylgdh"
        ]
        
        self.session = URLSession(configuration: config)
    }
    
    // 设置当前模型
    func setModel(_ model: DeepSeekModel) {
        self.currentModel = model
        print("已切换到模型: \(model.displayName) - \(model.description)")
    }
    
    // 获取当前模型
    func getCurrentModel() -> DeepSeekModel {
        return currentModel
    }
    
    // 标准请求（非流式）
    func sendMessage(_ messages: [Message]) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: baseURL) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // 将Message转换为ChatMessage格式
        let chatMessages = messages.map { message in
            ChatMessage(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            )
        }
        
        // 创建请求体
        let requestBody = ChatCompletionRequest(
            model: currentModel.rawValue,  // 使用当前选择的模型
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 移除了Authorization和Content-Type头，因为已经在session初始化时设置
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request) // 使用自定义的session
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 429:
                    throw APIError.rateLimited
                default:
                    if let errorMessage = String(data: data, encoding: .utf8) {
                        throw APIError.apiError(errorMessage)
                    } else {
                        throw APIError.apiError("状态码: \(httpResponse.statusCode)")
                    }
                }
            }
            .decode(type: ChatCompletionResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingFailed(error)
                } else {
                    return APIError.requestFailed(error)
                }
            }
            .map { response in
                if let message = response.choices?.first?.message?.content {
                    return message
                } else {
                    return "抱歉，我无法生成回复。"
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 流式请求，也使用自定义session
    func sendStreamMessage(_ messages: [Message]) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: baseURL) else {
            print("❌ API错误: URL无效")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // 记录请求开始
        print("📤 开始发送请求 - 模型: \(currentModel.displayName)")
        print("📤 消息数量: \(messages.count)条 - 最后一条: \(messages.last?.content.prefix(30) ?? "")...")
        
        // 将Message转换为ChatMessage格式
        let chatMessages = messages.map { message in
            ChatMessage(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            )
        }
        
        // 创建请求体，启用流式响应
        let requestBody = ChatCompletionRequest(
            model: currentModel.rawValue,  // 使用当前选择的模型
            messages: chatMessages,
            stream: true,
            max_tokens: 2048,
            temperature: 0.7,
            top_p: 0.7,
            top_k: 50,
            frequency_penalty: 0.5,
            n: 1,
            response_format: ChatCompletionRequest.ResponseFormat(type: "text")
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 已经不需要添加Authorization和Content-Type头
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
            print("📤 请求已准备 - Payload大小: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ 请求编码失败: \(error.localizedDescription)")
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        // 创建自定义发布者处理流式数据，并使用自定义session
        return StreamPublisher(request: request, session: session)
            .handleEvents(
                receiveSubscription: { _ in
                    print("🔄 开始连接API流")
                },
                receiveOutput: { output in
                    if output.count <= 20 {
                        print("📥 收到数据: \(output)")
                    } else {
                        print("📥 收到数据: \(output.prefix(20))... (长度: \(output.count))")
                    }
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ API流结束 - 成功")
                    case .failure(let error):
                        print("❌ API流错误: \(error.localizedDescription)")
                    }
                },
                receiveCancel: {
                    print("🛑 API流已取消")
                }
            )
            .mapError { error in
                print("❌ API错误: \(error.localizedDescription)")
                return APIError.requestFailed(error)
            }
            .eraseToAnyPublisher()
    }
}

// 自定义发布者处理流式响应
class StreamPublisher: Publisher {
    typealias Output = String
    typealias Failure = APIError
    
    private let request: URLRequest
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = StreamSubscription(subscriber: subscriber, request: request, session: session, decoder: decoder)
        subscriber.receive(subscription: subscription)
    }
    
    final class StreamSubscription<S: Subscriber>: Subscription where S.Input == String, S.Failure == APIError {
        private var subscriber: S?
        private var task: URLSessionDataTask?
        private var buffer = ""
        private let decoder: JSONDecoder
        private let session: URLSession
        
        init(subscriber: S, request: URLRequest, session: URLSession, decoder: JSONDecoder) {
            self.subscriber = subscriber
            self.decoder = decoder
            self.session = session
            
            Swift.print("🔌 创建数据流任务...")
            
            task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                // 处理错误
                if let error = error {
                    Swift.print("❌ 网络错误: \(error.localizedDescription)")
                    self.subscriber?.receive(completion: .failure(APIError.requestFailed(error)))
                    return
                }
                
                // 验证HTTP响应
                guard let httpResponse = response as? HTTPURLResponse else {
                    Swift.print("❌ 无效的HTTP响应")
                    self.subscriber?.receive(completion: .failure(APIError.invalidResponse))
                    return
                }
                
                Swift.print("📊 收到HTTP响应: 状态码\(httpResponse.statusCode)")
                
                // 处理HTTP错误
                switch httpResponse.statusCode {
                case 200...299:
                    Swift.print("✅ HTTP状态码正常: \(httpResponse.statusCode)")
                    break // 成功响应，继续处理
                case 401:
                    Swift.print("❌ 授权失败: 401")
                    self.subscriber?.receive(completion: .failure(APIError.unauthorized))
                    return
                case 429:
                    Swift.print("❌ 请求过多: 429")
                    self.subscriber?.receive(completion: .failure(APIError.rateLimited))
                    return
                default:
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        Swift.print("❌ API错误: \(errorMessage)")
                        self.subscriber?.receive(completion: .failure(APIError.apiError(errorMessage)))
                    } else {
                        Swift.print("❌ 未知错误: 状态码\(httpResponse.statusCode)")
                        self.subscriber?.receive(completion: .failure(APIError.apiError("状态码: \(httpResponse.statusCode)")))
                    }
                    return
                }
                
                // 处理流式数据
                guard let data = data else {
                    Swift.print("❌ 响应数据为空")
                    self.subscriber?.receive(completion: .failure(APIError.invalidResponse))
                    return
                }
                
                Swift.print("📦 收到数据大小: \(data.count) bytes")
                
                // 获取字符串并处理多行数据
                if let text = String(data: data, encoding: .utf8) {
                    let lines = text.components(separatedBy: "data: ")
                    Swift.print("📑 收到数据行数: \(lines.count)")
                    
                    var chunkCount = 0
                    var contentChunkCount = 0
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if trimmedLine.isEmpty || trimmedLine == "[DONE]" {
                            if trimmedLine == "[DONE]" {
                                Swift.print("🏁 收到结束标记: [DONE]")
                            }
                            continue
                        }
                        
                        do {
                            let chunkData = trimmedLine.data(using: .utf8)!
                            let chunk = try self.decoder.decode(ChatCompletionChunk.self, from: chunkData)
                            chunkCount += 1
                            
                            if let contentDelta = chunk.choices?.first?.delta?.content, !contentDelta.isEmpty {
                                contentChunkCount += 1
                                _ = self.subscriber?.receive(contentDelta)
                            }
                        } catch {
                            // 解析错误时跳过
                            Swift.print("⚠️ 解析数据块失败: \(error.localizedDescription)")
                            continue
                        }
                    }
                    
                    Swift.print("📊 解析结果: 总数据块\(chunkCount)个, 内容块\(contentChunkCount)个")
                    Swift.print("✅ 流式传输完成")
                    self.subscriber?.receive(completion: .finished)
                } else {
                    Swift.print("❌ 无法解析响应数据为文本")
                    self.subscriber?.receive(completion: .failure(APIError.invalidResponse))
                }
            }
            
            Swift.print("▶️ 开始执行网络请求...")
            task?.resume()
        }
        
        func request(_ demand: Subscribers.Demand) {
            // 这里不需要处理需求，因为我们会以自己的节奏发送事件
        }
        
        func cancel() {
            task?.cancel()
            subscriber = nil
        }
    }
} 