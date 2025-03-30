import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var expandedConversationId: UUID? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏
            HStack {
                Text("聊天记录")
                    .font(.system(size: 17, weight: .medium))
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索聊天记录", text: $searchText)
                    .font(.system(size: 16))
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // 聊天记录列表
            if viewModel.conversations.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("暂无聊天记录")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                conversationsList
            }
        }
    }
    
    private var conversationsList: some View {
        List {
            // 今天的对话
            let todayConversations = filterTodayConversations()
            if !todayConversations.isEmpty {
                Section(header: Text("今天").font(.system(size: 14)).foregroundColor(.gray)) {
                    ForEach(todayConversations) { conversation in
                        conversationRow(for: conversation)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteConversation(conversation)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            
            // 昨天的对话
            let yesterdayConversations = filterYesterdayConversations()
            if !yesterdayConversations.isEmpty {
                Section(header: Text("昨天").font(.system(size: 14)).foregroundColor(.gray)) {
                    ForEach(yesterdayConversations) { conversation in
                        conversationRow(for: conversation)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteConversation(conversation)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            
            // 更早的对话
            let earlierConversations = filterEarlierConversations()
            if !earlierConversations.isEmpty {
                Section(header: Text("更早").font(.system(size: 14)).foregroundColor(.gray)) {
                    ForEach(earlierConversations) { conversation in
                        conversationRow(for: conversation)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteConversation(conversation)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // 获取对话标题（用户第一句话，过长时截断）
    private func getConversationTitle(_ conversation: Conversation) -> String {
        // 获取用户的第一条消息
        if let firstUserMessage = conversation.messages.first(where: { $0.isUser }) {
            let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // 如果标题超过20个字符，截断并添加省略号
            if content.count > 20 {
                return String(content.prefix(20)) + "..."
            }
            return content
        }
        // 如果没有用户消息，返回默认标题
        return conversation.title
    }
    
    private func conversationRow(for conversation: Conversation) -> some View {
        VStack(spacing: 0) {
            // 对话基本信息行
            Button(action: {
                if expandedConversationId == conversation.id {
                    expandedConversationId = nil // 如果已展开，则收起
                } else {
                    expandedConversationId = conversation.id // 如果未展开，则展开
                }
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // 显示第一条用户消息内容作为标题（截断处理）
                        Text(getConversationTitle(conversation))
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // 展开/收起指示器
                        Image(systemName: expandedConversationId == conversation.id ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    // 时间信息行
                    HStack {
                        Text(formatTime(conversation.date))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // 显示消息数量
                        Text("\(conversation.messages.count)条消息")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 展开的对话内容
            if expandedConversationId == conversation.id {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation.messages.prefix(6)) { message in
                        HStack(alignment: .top) {
                            // 用户图标或AI图标
                            Image(systemName: message.isUser ? "person.circle.fill" : "brain")
                                .font(.system(size: 14))
                                .foregroundColor(message.isUser ? .blue : .purple)
                                .frame(width: 16, height: 16)
                            
                            // 消息内容
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.isUser ? "你" : "元气大宝")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(message.isUser ? .blue : .purple)
                                
                                Text(message.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    // 如果消息超过6条，显示"查看更多"按钮
                    if conversation.messages.count > 6 {
                        Button(action: {
                            viewModel.selectConversation(conversation)
                            isPresented = false
                        }) {
                            Text("查看完整对话")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.vertical, 8)
            }
            
            // 查看按钮
            if expandedConversationId != conversation.id {
                Button(action: {
                    viewModel.selectConversation(conversation)
                    isPresented = false
                }) {
                    Text("继续对话")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 详细时间格式化工具
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "昨天 " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: date)
        }
    }
    
    // 日期格式化工具
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
    
    // 过滤今天的对话
    private func filterTodayConversations() -> [Conversation] {
        let calendar = Calendar.current
        return viewModel.conversations.filter { 
            calendar.isDateInToday($0.date) &&
            (searchText.isEmpty || $0.title.contains(searchText) || 
             $0.messages.first(where: { $0.isUser })?.content.contains(searchText) == true)
        }
    }
    
    // 过滤昨天的对话
    private func filterYesterdayConversations() -> [Conversation] {
        let calendar = Calendar.current
        return viewModel.conversations.filter { 
            calendar.isDateInYesterday($0.date) &&
            (searchText.isEmpty || $0.title.contains(searchText) || 
             $0.messages.first(where: { $0.isUser })?.content.contains(searchText) == true)
        }
    }
    
    // 过滤更早的对话
    private func filterEarlierConversations() -> [Conversation] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        
        return viewModel.conversations.filter { 
            $0.date < yesterdayStart &&
            (searchText.isEmpty || $0.title.contains(searchText) || 
             $0.messages.first(where: { $0.isUser })?.content.contains(searchText) == true)
        }
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView(
            viewModel: ChatViewModel(),
            isPresented: .constant(true)
        )
    }
} 