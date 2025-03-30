import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    var content: String
    let isUser: Bool
    let date: Date
    var importance: Int = 0  // 新增：消息重要性评分，用于记忆选择
    var isContextual: Bool = true  // 新增：是否作为上下文发送给API
    var keywords: [String] = []  // 新增：消息关键词，用于主题聚类和检索
    
    init(content: String, isUser: Bool, date: Date = Date(), importance: Int = 0, isContextual: Bool = true) {
        self.content = content
        self.isUser = isUser
        self.date = date
        self.importance = importance
        self.isContextual = isContextual
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.date == rhs.date &&
        lhs.importance == rhs.importance &&
        lhs.isContextual == rhs.isContextual
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var messages: [Message]
    var date: Date
    var summaries: [ConversationSummary] = []  // 新增：对话摘要列表
    var topics: [String] = []  // 新增：对话主题标签
    var contextStrategy: ContextStrategy = .recentMessages  // 新增：上下文策略
    
    init(title: String, messages: [Message] = [], date: Date = Date(), 
         summaries: [ConversationSummary] = [], topics: [String] = [], 
         contextStrategy: ContextStrategy = .recentMessages) {
        self.title = title
        self.messages = messages
        self.date = date
        self.summaries = summaries
        self.topics = topics
        self.contextStrategy = contextStrategy
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.messages == rhs.messages &&
        lhs.date == rhs.date &&
        lhs.summaries == rhs.summaries &&
        lhs.topics == rhs.topics &&
        lhs.contextStrategy == rhs.contextStrategy
    }
    
    // 新增：获取发送给API的上下文消息
    func getContextMessages(maxTokens: Int = 4000) -> [Message] {
        switch contextStrategy {
        case .recentMessages:
            // 简单返回最近的消息，可以根据maxTokens进行限制
            return messages.suffix(20) // 默认取最近20条
        case .importantMessages:
            // 按重要性排序，选取重要消息
            let sortedMessages = messages.filter { $0.isContextual }
                .sorted { $0.importance > $1.importance }
            return Array(sortedMessages.prefix(20))
        case .summarizedContext:
            // 如果有摘要，优先使用摘要作为上下文背景，然后加上最近的消息
            if let latestSummary = summaries.last {
                let summaryMessage = Message(
                    content: "对话背景：\(latestSummary.content)", 
                    isUser: false, 
                    isContextual: true
                )
                return [summaryMessage] + messages.suffix(10)
            } else {
                return messages.suffix(20)
            }
        }
    }
}

// 新增：对话摘要结构
struct ConversationSummary: Identifiable, Codable, Equatable {
    var id = UUID()
    var content: String
    var date: Date
    var messageRange: ClosedRange<Int>  // 摘要涵盖的消息范围（索引）
    
    static func == (lhs: ConversationSummary, rhs: ConversationSummary) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.date == rhs.date &&
        lhs.messageRange == rhs.messageRange
    }
}

// 新增：上下文策略枚举
enum ContextStrategy: String, Codable {
    case recentMessages = "最近消息"
    case importantMessages = "重要消息"
    case summarizedContext = "摘要上下文"
} 