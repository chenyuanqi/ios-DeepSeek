import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var currentMessages: [Message] = []
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var streamingText = ""
    @Published var isStreaming = false
    @Published var isDeepThinkingEnabled = false  // 是否启用深度思考模式
    @Published var thinkingPrompt: String = "正在思考..." // 思考提示文本
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var thinkingTimer: Timer?
    private var thinkingDots = 0
    
    private let thinkingPrompts = [
        "正在思考",
        "深入分析中",
        "处理信息中",
        "整理思路中",
        "构建回答中"
    ]
    
    private let sampleResponses = [
        "这是一个很有趣的问题。根据我的理解...",
        "我认为这个问题可以从几个方面来看...",
        "这是个复杂的问题，让我尝试解释一下...",
        "根据最新研究表明...",
        "从历史角度来看，这个问题...",
        "这是个有深度的问题，我的看法是..."
    ]
    
    init() {
        loadConversations()
        
        // 如果没有对话，创建一个新的
        if currentConversation == nil {
            startNewConversation()
        }
    }
    
    // 切换深度思考模式
    func toggleDeepThinking(_ enabled: Bool) {
        isDeepThinkingEnabled = enabled
        
        // 根据当前模式设置模型
        if enabled {
            apiService.setModel(.r1)  // 切换到DeepSeek-R1模型
            print("🧠 已切换到深度思考模式: DeepSeek-R1")
        } else {
            apiService.setModel(.v3)  // 切换回默认的DeepSeek-V3模型
            print("🧠 已切换到标准模式: DeepSeek-V3")
        }
    }
    
    // 获取当前模型名称
    func getCurrentModelName() -> String {
        return apiService.getCurrentModel().displayName
    }
    
    // 启动思考动画
    private func startThinkingAnimation() {
        // 随机选择一个思考提示
        let basePrompt = thinkingPrompts.randomElement() ?? "正在思考"
        thinkingPrompt = basePrompt
        thinkingDots = 0
        
        // 创建计时器，每0.5秒更新一次思考提示
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.thinkingDots = (self.thinkingDots + 1) % 4
            let dots = String(repeating: ".", count: self.thinkingDots)
            self.thinkingPrompt = basePrompt + dots
        }
    }
    
    // 停止思考动画
    private func stopThinkingAnimation() {
        thinkingTimer?.invalidate()
        thinkingTimer = nil
    }
    
    func sendMessage(_ content: String) {
        print("📱 用户发送消息: \(content)")
        
        // 创建并添加用户消息
        let userMessage = Message(content: content, isUser: true)
        currentMessages.append(userMessage)
        
        // 更新当前对话
        if var conversation = currentConversation {
            conversation.messages.append(userMessage)
            currentConversation = conversation
            updateConversation(conversation)
        }
        
        // 设置加载状态
        isLoading = true
        isStreaming = true
        errorMessage = nil
        streamingText = ""
        
        // 开始思考动画
        startThinkingAnimation()
        
        // 创建一个临时的AI消息，用于流式更新
        let temporaryAIMessage = Message(content: "", isUser: false)
        currentMessages.append(temporaryAIMessage)
        
        print("🤖 开始请求AI响应...")
        
        // 调用API获取流式响应
        apiService.sendStreamMessage(currentMessages)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.isStreaming = false
                    self?.stopThinkingAnimation() // 停止思考动画
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ AI响应失败: \(error.localizedDescription)")
                        
                        // 如果API调用失败，添加一个错误消息
                        let errorContent = "抱歉，发生了错误：\(error.localizedDescription)"
                        
                        // 更新临时消息或添加新的错误消息
                        if let lastMessage = self?.currentMessages.last, !lastMessage.isUser {
                            self?.updateLastAIMessage(content: errorContent)
                        } else {
                            let errorMessage = Message(content: errorContent, isUser: false)
                            self?.addAIMessage(errorMessage)
                        }
                    } else {
                        print("✅ AI响应完成，总字数: \(self?.streamingText.count ?? 0)")
                        // 成功完成流式传输，更新最后的消息
                        if !self!.streamingText.isEmpty {
                            // 处理空行
                            let processedText = self!.streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
                            self?.updateLastAIMessage(content: processedText)
                        }
                    }
                },
                receiveValue: { [weak self] chunk in
                    // 处理流式响应的每一个块
                    guard let self = self else { return }
                    
                    // 如果是第一个块，停止思考动画
                    if self.streamingText.isEmpty {
                        print("📝 收到第一个响应块，开始构建回答...")
                        self.stopThinkingAnimation()
                    }
                    
                    self.streamingText += chunk
                    
                    // 更新最后一条消息的内容
                    self.updateLastAIMessage(content: self.streamingText)
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateLastAIMessage(content: String) {
        // 更新数组中最后一条AI消息的内容
        if let index = currentMessages.lastIndex(where: { !$0.isUser }) {
            var updatedMessage = currentMessages[index]
            updatedMessage.content = content
            currentMessages[index] = updatedMessage
            
            // 更新当前对话
            if var conversation = currentConversation {
                if let conversationIndex = conversation.messages.lastIndex(where: { !$0.isUser }) {
                    conversation.messages[conversationIndex].content = content
                    currentConversation = conversation
                    // 不要每次流式更新都保存对话，太频繁
                }
            }
        }
    }
    
    private func addAIMessage(_ message: Message) {
        // 添加AI响应
        currentMessages.append(message)
        
        // 更新当前对话
        if var conversation = currentConversation {
            conversation.messages.append(message)
            
            // 如果是第一条消息，使用用户消息内容作为对话标题
            if conversation.messages.count == 2 {
                let userContent = conversation.messages.first?.content ?? ""
                conversation.title = userContent.count > 20 ? 
                    String(userContent.prefix(20)) + "..." : 
                    userContent
            }
            
            currentConversation = conversation
            updateConversation(conversation)
        }
    }
    
    func startNewConversation() {
        let newConversation = Conversation(title: "新对话")
        currentConversation = newConversation
        conversations.insert(newConversation, at: 0)
        currentMessages = []
        saveConversations()
    }
    
    func selectConversation(_ conversation: Conversation) {
        currentConversation = conversation
        currentMessages = conversation.messages
    }
    
    private func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            saveConversations()
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "savedConversations")
        }
    }
    
    private func loadConversations() {
        if let savedConversations = UserDefaults.standard.data(forKey: "savedConversations"),
           let decodedConversations = try? JSONDecoder().decode([Conversation].self, from: savedConversations) {
            conversations = decodedConversations
            if let latest = conversations.first {
                currentConversation = latest
                currentMessages = latest.messages
            }
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
        
        // 如果删除的是当前对话，选择第一个对话或创建新对话
        if currentConversation?.id == conversation.id {
            if let first = conversations.first {
                selectConversation(first)
            } else {
                startNewConversation()
            }
        }
    }
} 