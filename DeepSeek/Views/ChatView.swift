import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var showingChatHistory = false
    @State private var isFirstAppearance = true
    @State private var previousMessageCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        showingChatHistory = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("元宝")
                            .font(.system(size: 17, weight: .medium))
                        Text("DeepSeek")
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.startNewConversation()
                        isFirstAppearance = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .frame(height: 44)
                
                // 功能未开发提示
                if let message = viewModel.featureNotAvailableMessage {
                    HStack {
                        Text(message)
                            .font(.system(size: 14))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.featureNotAvailableMessage != nil)
                }
                
                // 聊天内容区域
                ScrollViewReader { scrollView in
                    ScrollView {
                        if viewModel.currentMessages.isEmpty && isFirstAppearance {
                            // 欢迎视图（仅当没有消息时显示）
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Hi~ 我是元宝")
                                        .font(.system(size: 24, weight: .medium))
                                    
                                    Text("你身边的智能助手，可以为你答疑解惑、尽情创作，快来点击以下任一功能体验吧～")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                
                                // 示例问题列表
                                VStack(spacing: 12) {
                                    QuestionButton(text: "自动推送的\"猜你喜欢\"是否比伴侣更懂你？") {
                                        sendSampleQuestion("自动推送的\"猜你喜欢\"是否比伴侣更懂你？")
                                    }
                                    QuestionButton(text: "如果超级英雄需要考编制，灭霸能过政审吗？") {
                                        sendSampleQuestion("如果超级英雄需要考编制，灭霸能过政审吗？")
                                    }
                                    QuestionButton(text: "蚊子吸血时哼的是不是《感恩的心》？") {
                                        sendSampleQuestion("蚊子吸血时哼的是不是《感恩的心》？")
                                    }
                                }
                                .padding(.horizontal)
                                
                                // 底部提示文本
                                HStack {
                                    Text("对话记录可以在侧边栏找到哦")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Button("去看看") {
                                        showingChatHistory = true
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                }
                                .padding()
                            }
                        } else {
                            // 显示消息
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.currentMessages) { message in
                                    MessageView(message: message, isTyping: viewModel.isStreaming && message == viewModel.currentMessages.last && !message.isUser)
                                        .id(message.id)
                                }
                                
                                // 显示加载中指示器
                                if viewModel.isLoading && !viewModel.isStreaming {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Text(viewModel.thinkingPrompt)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(.leading, 8)
                                            .animation(.easeInOut, value: viewModel.thinkingPrompt)
                                        Spacer()
                                    }
                                    .padding()
                                    .id("loading")
                                }
                                
                                // 显示错误消息
                                if let errorMessage = viewModel.errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                        Text(errorMessage)
                                            .font(.system(size: 14))
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                    .padding()
                                    .id("error")
                                }
                            }
                            .padding()
                        }
                    }
                    .onReceive(viewModel.$currentMessages) { messages in
                        if messages.count > previousMessageCount {
                            if let lastMessage = messages.last {
                                withAnimation {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                            // 有消息后不再显示欢迎视图
                            if !messages.isEmpty {
                                isFirstAppearance = false
                            }
                            previousMessageCount = messages.count
                        }
                    }
                    .onReceive(viewModel.$streamingText) { _ in
                        // 当流式文本更新时，滚动到最后一条消息
                        if viewModel.isStreaming, let lastMessage = viewModel.currentMessages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onReceive(viewModel.$isLoading) { isLoading in
                        if isLoading && !viewModel.isStreaming {
                            withAnimation {
                                scrollView.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                    .onReceive(viewModel.$errorMessage) { _ in
                        if viewModel.errorMessage != nil {
                            withAnimation {
                                scrollView.scrollTo("error", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 底部输入区域
                VStack(spacing: 0) {
                    Divider()
                    
                    // 快捷按钮区域
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.toggleDeepThinking(!viewModel.isDeepThinkingEnabled)
                        }) {
                            HStack {
                                Text("RI • 深度思考")
                                    .font(.system(size: 14))
                                    .foregroundColor(viewModel.isDeepThinkingEnabled ? .white : .black)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.isDeepThinkingEnabled ? Color.blue : Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        Button(action: {
                            // 显示功能未开发提示
                            viewModel.showFeatureNotAvailableMessage("联网功能正在开发中，敬请期待！")
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("联网")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        Spacer()
                        
                        // 显示当前模型指示
                        if viewModel.isDeepThinkingEnabled {
                            Text("R1模式")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // 输入框区域
                    HStack(spacing: 12) {
                        TextField("有问题尽管问我", text: $messageText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(18)
                            .disabled(viewModel.isLoading)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(viewModel.isLoading ? .gray : .blue)
                        }
                        .disabled(messageText.isEmpty || viewModel.isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $showingChatHistory) {
                ChatHistoryView(viewModel: viewModel, isPresented: $showingChatHistory)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty && !viewModel.isLoading else { return }
        
        let message = messageText
        messageText = ""
        
        viewModel.sendMessage(message)
    }
    
    private func sendSampleQuestion(_ question: String) {
        guard !viewModel.isLoading else { return }
        
        messageText = question
        sendMessage()
    }
}

// 消息气泡视图
struct MessageView: View {
    let message: Message
    var isTyping: Bool = false
    @State private var cursorVisible = false
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .cornerRadius(4, corners: [.bottomRight])
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                HStack(alignment: .bottom, spacing: 0) {
                    // 处理消息内容，确保没有前导空行
                    let processedContent = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    Text(processedContent.isEmpty && isTyping ? " " : processedContent)
                    
                    // 如果正在输入中，显示打字光标
                    if isTyping {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2, height: 16)
                            .opacity(cursorVisible ? 1 : 0)
                            .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: cursorVisible)
                            .onAppear {
                                cursorVisible = true
                            }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .foregroundColor(.black)
                .cornerRadius(16)
                .cornerRadius(4, corners: [.bottomLeft])
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

// 自定义圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 问题按钮组件
struct QuestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// 预览
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
} 
