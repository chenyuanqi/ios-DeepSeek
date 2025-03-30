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
    @Published var featureNotAvailableMessage: String? // 功能未开发提示
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var thinkingTimer: Timer?
    private var thinkingDots = 0
    
    // 用于清除提示消息的计时器
    private var messageTimer: Timer?
    
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
    
    // 新增：触发对话记忆优化
    func optimizeConversationMemory() {
        guard let conversation = currentConversation, conversation.messages.count > 10 else {
            print("📝 对话记忆优化：消息不足，跳过优化")
            return // 消息太少，不需要优化
        }
        
        // 分析所有消息的重要性
        analyzeMessageImportance(for: conversation)
        
        // 根据消息数量决定是否生成摘要
        if conversation.messages.count > 20 && conversation.summaries.isEmpty {
            // 为前20条消息生成摘要
            generateSummary(for: conversation, range: 0...19)
        } else if conversation.messages.count > 30 && conversation.summaries.count == 1 {
            // 为新增的消息生成新摘要
            let lastSummaryEnd = conversation.summaries.last?.messageRange.upperBound ?? 0
            if conversation.messages.count - lastSummaryEnd > 20 {
                generateSummary(for: conversation, range: lastSummaryEnd...(conversation.messages.count - 1))
            }
        }
        
        // 提取对话主题
        if conversation.topics.isEmpty && conversation.messages.count >= 5 {
            extractConversationTopics(for: conversation)
        }
    }
    
    // 新增：分析消息重要性
    private func analyzeMessageImportance(for conversation: Conversation) {
        guard var mutableConversation = currentConversation else { return }
        
        // 获取未分析重要性的消息（只处理importance为0的消息）
        let messagesToAnalyze = mutableConversation.messages.enumerated().filter { $0.element.importance == 0 }
        
        guard !messagesToAnalyze.isEmpty else {
            print("📝 重要性分析：没有需要分析的消息")
            return
        }
        
        print("📝 开始分析消息重要性，共\(messagesToAnalyze.count)条消息")
        
        // 为每条消息进行重要性分析（这里可以优化为批量分析）
        for (index, message) in messagesToAnalyze {
            // 过滤掉短消息，默认不重要
            if message.content.count < 10 {
                mutableConversation.messages[index].importance = 2
                continue
            }
            
            apiService.analyzeImportance(message: message)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 消息重要性分析失败: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { [weak self] importance in
                        guard let self = self else { return }
                        
                        print("📝 消息重要性分析结果: \(importance)")
                        
                        // 更新消息重要性
                        if var conversation = self.currentConversation, 
                           index < conversation.messages.count {
                            conversation.messages[index].importance = importance
                            self.currentConversation = conversation
                            
                            // 只有当分析了所有消息后才保存对话
                            if !conversation.messages.contains(where: { $0.importance == 0 }) {
                                self.updateConversation(conversation)
                                print("📝 所有消息重要性分析完成，已保存对话")
                            }
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // 新增：生成对话摘要
    private func generateSummary(for conversation: Conversation, range: ClosedRange<Int>) {
        print("📝 开始生成对话摘要，消息范围: \(range)")
        
        apiService.generateSummary(for: conversation.messages, range: range)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 摘要生成失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] summary in
                    guard let self = self else { return }
                    
                    print("📝 成功生成摘要: \(summary.content.prefix(30))...")
                    
                    // 更新对话摘要
                    if var conversation = self.currentConversation {
                        conversation.summaries.append(summary)
                        
                        // 如果摘要策略是默认的，切换到摘要上下文策略
                        if conversation.contextStrategy == .recentMessages {
                            conversation.contextStrategy = .summarizedContext
                            print("📝 已切换到摘要上下文策略")
                        }
                        
                        self.currentConversation = conversation
                        self.updateConversation(conversation)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 新增：提取对话主题
    private func extractConversationTopics(for conversation: Conversation) {
        print("📝 开始提取对话主题")
        
        // 构建用于主题提取的提示
        let topicsPrompt = """
        请从以下对话中提取3-5个主题标签，以逗号分隔。只返回主题标签列表，不要有其他内容。
        
        \(conversation.messages.prefix(min(10, conversation.messages.count)).map { 
            ($0.isUser ? "用户: " : "AI: ") + $0.content 
        }.joined(separator: "\n\n"))
        
        主题标签:
        """
        
        // 创建一个临时消息用于API请求
        let tempMessage = Message(content: topicsPrompt, isUser: true, isContextual: false)
        
        apiService.extractKeywords(message: tempMessage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 主题提取失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] topics in
                    guard let self = self else { return }
                    
                    print("📝 成功提取主题: \(topics.joined(separator: ", "))")
                    
                    // 更新对话主题
                    if var conversation = self.currentConversation {
                        conversation.topics = topics
                        self.currentConversation = conversation
                        self.updateConversation(conversation)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 新增：更改上下文策略
    func changeContextStrategy(_ strategy: ContextStrategy) {
        if var conversation = currentConversation {
            conversation.contextStrategy = strategy
            print("📝 切换上下文策略: \(strategy.rawValue)")
            currentConversation = conversation
            updateConversation(conversation)
        }
    }
    
    // 修改：发送消息方法，使用对话上下文
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
        
        // 调用API获取流式响应，传入当前对话以使用记忆功能
        apiService.sendStreamMessage(currentMessages, conversation: currentConversation)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    self.isStreaming = false
                    self.stopThinkingAnimation() // 停止思考动画
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                        print("❌ AI响应失败: \(error.localizedDescription)")
                        
                        // 如果API调用失败，添加一个错误消息
                        let errorContent = "抱歉，发生了错误：\(error.localizedDescription)"
                        
                        // 更新临时消息或添加新的错误消息
                        if let lastMessage = self.currentMessages.last, !lastMessage.isUser {
                            self.updateLastAIMessage(content: errorContent)
                        } else {
                            let errorMessage = Message(content: errorContent, isUser: false)
                            self.addAIMessage(errorMessage)
                        }
                    } else {
                        print("✅ AI响应完成，总字数: \(self.streamingText.count)")
                        
                        // 成功完成流式传输，确保最后的消息内容正确
                        if !self.streamingText.isEmpty {
                            // 处理空行
                            let processedText = self.streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // 更新最后一条AI消息的内容
                            if let lastMessage = self.currentMessages.last, !lastMessage.isUser {
                                self.updateLastAIMessage(content: processedText)
                                
                                // 保存对话记录
                                if var conversation = self.currentConversation {
                                    if !conversation.messages.contains(where: { !$0.isUser && $0.content == processedText }) {
                                        // 确保消息已正确保存到对话中
                                        let aiMessage = Message(content: processedText, isUser: false)
                                        conversation.messages = conversation.messages.filter { $0.isUser || $0.content != "" }
                                        conversation.messages.append(aiMessage)
                                        self.currentConversation = conversation
                                    }
                                    self.updateConversation(conversation)
                                    
                                    // 如果对话消息达到一定数量，触发记忆优化
                                    if conversation.messages.count >= 10 {
                                        // 使用异步队列执行，避免阻塞主线程
                                        DispatchQueue.global(qos: .background).async {
                                            DispatchQueue.main.async {
                                                self.optimizeConversationMemory()
                                            }
                                        }
                                    }
                                }
                            } else {
                                // 如果没有找到最后一条AI消息，创建一个新的
                                let aiMessage = Message(content: processedText, isUser: false)
                                self.addAIMessage(aiMessage)
                            }
                            
                            // 打印保存状态
                            print("📊 对话保存状态：\(self.currentConversation?.messages.count ?? 0)条消息")
                            self.currentConversation?.messages.forEach { msg in
                                print("  \(msg.isUser ? "👤" : "🤖") \(msg.content.prefix(20))...")
                            }
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
                    
                    print("📄 收到内容块: \(chunk.prefix(min(20, chunk.count)))...")
                    
                    // 添加新的内容块
                    self.streamingText += chunk
                    
                    // 实时更新最后一条消息的内容
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
            
            // 同时更新当前对话中的消息内容
            if var conversation = currentConversation {
                if let conversationIndex = conversation.messages.lastIndex(where: { !$0.isUser }) {
                    conversation.messages[conversationIndex].content = content
                    currentConversation = conversation
                    // 不要每次流式更新都保存对话，太频繁
                    // 只在接收完成时保存
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
            
            // 如果是第一条AI消息回复，使用用户的第一条消息作为对话标题
            if conversation.messages.count == 2 && conversation.title == "新对话" {
                if let userMessage = conversation.messages.first(where: { $0.isUser }) {
                    let userContent = userMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    // 如果用户消息超过20个字符，截断并添加省略号
                    conversation.title = userContent.count > 20 ? 
                        String(userContent.prefix(20)) + "..." : 
                        userContent
                }
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
    
    // 显示功能未开发提示
    func showFeatureNotAvailableMessage(_ message: String) {
        self.featureNotAvailableMessage = message
        
        // 3秒后自动清除提示
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.featureNotAvailableMessage = nil
            }
        }
    }
    
    deinit {
        messageTimer?.invalidate()
        thinkingTimer?.invalidate()
    }
} 