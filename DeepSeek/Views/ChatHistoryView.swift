import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
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
                    }
                    .onDelete { indexSet in
                        deleteConversations(from: todayConversations, at: indexSet)
                    }
                }
            }
            
            // 昨天的对话
            let yesterdayConversations = filterYesterdayConversations()
            if !yesterdayConversations.isEmpty {
                Section(header: Text("昨天").font(.system(size: 14)).foregroundColor(.gray)) {
                    ForEach(yesterdayConversations) { conversation in
                        conversationRow(for: conversation)
                    }
                    .onDelete { indexSet in
                        deleteConversations(from: yesterdayConversations, at: indexSet)
                    }
                }
            }
            
            // 更早的对话
            let earlierConversations = filterEarlierConversations()
            if !earlierConversations.isEmpty {
                Section(header: Text("更早").font(.system(size: 14)).foregroundColor(.gray)) {
                    ForEach(earlierConversations) { conversation in
                        conversationRow(for: conversation)
                    }
                    .onDelete { indexSet in
                        deleteConversations(from: earlierConversations, at: indexSet)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func conversationRow(for conversation: Conversation) -> some View {
        Button(action: {
            viewModel.selectConversation(conversation)
            isPresented = false
        }) {
            HStack {
                Text(conversation.title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Spacer()
                Text(formatDate(conversation.date))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
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
            (searchText.isEmpty || $0.title.contains(searchText))
        }
    }
    
    // 过滤昨天的对话
    private func filterYesterdayConversations() -> [Conversation] {
        let calendar = Calendar.current
        return viewModel.conversations.filter { 
            calendar.isDateInYesterday($0.date) &&
            (searchText.isEmpty || $0.title.contains(searchText))
        }
    }
    
    // 过滤更早的对话
    private func filterEarlierConversations() -> [Conversation] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        
        return viewModel.conversations.filter { 
            $0.date < yesterdayStart &&
            (searchText.isEmpty || $0.title.contains(searchText))
        }
    }
    
    // 删除对话
    private func deleteConversations(from conversations: [Conversation], at indexSet: IndexSet) {
        for index in indexSet {
            let conversationToDelete = conversations[index]
            viewModel.deleteConversation(conversationToDelete)
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