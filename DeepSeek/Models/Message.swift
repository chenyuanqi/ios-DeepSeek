import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    var content: String
    let isUser: Bool
    let date: Date
    
    init(content: String, isUser: Bool, date: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.date = date
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.date == rhs.date
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var messages: [Message]
    var date: Date
    
    init(title: String, messages: [Message] = [], date: Date = Date()) {
        self.title = title
        self.messages = messages
        self.date = date
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.messages == rhs.messages &&
        lhs.date == rhs.date
    }
} 