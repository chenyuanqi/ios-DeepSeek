import SwiftUI
import MarkdownUI

// 自定义Markdown主题
extension Theme {
    static var deepSeekTheme: Theme {
        Theme()
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(Color(.systemGray6).opacity(0.5))
                ForegroundColor(.primary)
            }
            .codeBlock { configuration in
                configuration
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .markdownMargin(top: 4, bottom: 8)
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
            }
            .heading1 { configuration in
                configuration
                    .markdownMargin(top: 20, bottom: 10)
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.6))
                    }
            }
            .heading2 { configuration in
                configuration
                    .markdownMargin(top: 16, bottom: 8)
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.4))
                    }
            }
            .heading3 { configuration in
                configuration
                    .markdownMargin(top: 12, bottom: 6)
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.2))
                    }
            }
            .blockquote { configuration in
                configuration
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .overlay(
                        Rectangle()
                            .fill(Color.blue.opacity(0.4))
                            .frame(width: 4)
                        ,
                        alignment: .leading
                    )
                    .cornerRadius(6)
            }
            .table { configuration in
                configuration
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .markdownMargin(top: 0, bottom: 20)
            }
            .strong {
                FontWeight(.bold)
                ForegroundColor(.primary.opacity(0.9))
            }
            .emphasis {
                FontStyle(.italic)
            }
            .link {
                ForegroundColor(.blue)
                UnderlineStyle(.single)
            }
            .listItem { configuration in
                configuration
                    .markdownMargin(top: 0, bottom: 0)
            }
            .taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isCompleted ? .green : .primary)
                    .imageScale(.small)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
            }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var messageText = ""
    @State private var showingChatHistory = false
    @State private var isFirstAppearance = true
    @State private var previousMessageCount = 0
    @State private var showingProfileMenu = false
    @State private var showingProfileEdit = false
    @State private var showingThemeSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        showingChatHistory = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                    
                    // 隐藏中间标题
                    // HStack(spacing: 4) {
                    //     Text("元气大宝")
                    //         .font(.system(size: 17, weight: .medium))
                    //     Image(systemName: "chevron.down")
                    //         .font(.system(size: 14))
                    //         .foregroundColor(.gray)
                    // }
                    
                    Spacer()
                    
                    // 用户头像菜单
                    Button(action: {
                        showingProfileMenu = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.primary)
                            .imageScale(.large)
                    }
                    .confirmationDialog("个人设置", isPresented: $showingProfileMenu, titleVisibility: .visible) {
                        Button("主题切换") {
                            showingThemeSettings = true
                        }
                        Button("修改个人资料") {
                            showingProfileEdit = true
                        }
                        Button("退出登录", role: .destructive, action: {
                            authViewModel.logout()
                        })

                        Button("取消", role: .cancel, action: {})
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
                                    // 添加欢迎用户名
                                    if let username = authViewModel.currentUser?.username {
                                        Text("Hi~ \(username)，我是元气大宝")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    } else {
                                        Text("Hi~ 我是元气大宝")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    
                                    Text("你身边的智能助手，可以为你答疑解惑、尽情创作，快来点击以下任一功能体验吧～")
                                        .font(.system(size: 16))
                                        .foregroundColor(colorScheme == .dark ? Color(.systemGray4) : .gray)
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
                                        .foregroundColor(colorScheme == .dark ? Color(.systemGray4) : .gray)
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
                                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .gray))
                                        Text(viewModel.thinkingPrompt)
                                            .font(.system(size: 14))
                                            .foregroundColor(colorScheme == .dark ? Color(.systemGray4) : .gray)
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
                    .onReceive(viewModel.$streamingText) { text in
                        // 当流式文本更新时，确保滚动到最后一条消息
                        if viewModel.isStreaming, let lastMessage = viewModel.currentMessages.last {
                            // 使用比较短的动画时间，让滚动更及时
                            withAnimation(.easeOut(duration: 0.2)) {
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
                                    .foregroundColor(viewModel.isDeepThinkingEnabled ? .white : (colorScheme == .dark ? .white : .black))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.isDeepThinkingEnabled ? Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                            .cornerRadius(16)
                        }
                        
                        // 记忆策略按钮暂时隐藏
                        // ContextStrategyButton(viewModel: viewModel)
                        
                        // 新建对话按钮 - 现在是第三个按钮
                        Button(action: {
                            viewModel.startNewConversation()
                            isFirstAppearance = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("新对话")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
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
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
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
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
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
    @State private var currentTime = Date()
    @Environment(\.colorScheme) var colorScheme
    // 添加处理自动链接的状态
    @State private var detectedLinks: [URL] = []
    // 添加控制打字效果的状态
    @State private var displayedContentIndex: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 4) {
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
                        let processedContent = processMessageContent(message.content)
                        
                        if processedContent.isEmpty && isTyping {
                            Text(" ") // 空内容但正在输入时显示一个空格，以显示光标
                        } else {
                            // 使用自定义主题的Markdown视图
                            Markdown(isTyping ? visibleContent(from: processedContent) : processedContent)
                                .markdownTheme(.deepSeekTheme)
                                .markdownTextStyle {
                                    // 根据深色模式调整文本颜色
                                    ForegroundColor(colorScheme == .dark ? .white : .black)
                                    BackgroundColor(nil) // 移除背景色，避免与气泡背景冲突
                                }
                                // 根据深色模式定制代码块样式
                                .markdownBlockStyle(\.codeBlock) { configuration in
                                    configuration
                                        .padding()
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.5))
                                        .cornerRadius(8)
                                        .markdownTextStyle {
                                            FontFamilyVariant(.monospaced)
                                            FontSize(.em(0.85))
                                            ForegroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                }
                                .animation(.easeIn(duration: 0.05), value: isTyping ? visibleContent(from: processedContent) : processedContent) // 更短的动画时间
                        }
                        
                        // 如果正在输入中，显示打字光标
                        if isTyping {
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                                .frame(width: 2, height: 16)
                                .opacity(cursorVisible ? 1 : 0)
                                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: cursorVisible)
                                .onAppear {
                                    cursorVisible = true
                                }
                        }
                    }
                    .padding(12)
                    .background(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray6))
                    .cornerRadius(16)
                    .cornerRadius(4, corners: [.bottomLeft])
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                    
                    Spacer()
                }
            }
            
            // 消息时间显示
            HStack {
                if message.isUser {
                    Spacer()
                    Text(formatTime(currentTime))
                        .font(.system(size: 10))
                        .foregroundColor(colorScheme == .dark ? Color(.systemGray4) : .gray)
                } else {
                    Text(formatTime(currentTime))
                        .font(.system(size: 10))
                        .foregroundColor(colorScheme == .dark ? Color(.systemGray4) : .gray)
                    Spacer()
                }
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            // 使用当前时间，而不是消息的时间
            currentTime = Date()
            // 检测纯文本中的URL链接
            if !message.isUser {
                detectLinks(in: message.content)
                
                // 如果是AI消息且正在输入中，设置计时器实现打字机效果
                if isTyping {
                    displayedContentIndex = 0
                    startTypewriterEffect()
                }
            }
        }
        .onChange(of: message.content) { newContent in
            // 当消息内容更新时，如果是AI正在输入的消息，重置显示进度
            if isTyping && !message.isUser {
                startTypewriterEffect()
            }
        }
        .onDisappear {
            // 清理计时器
            timer?.invalidate()
            timer = nil
        }
    }
    
    // 实现打字机效果的辅助方法
    private func startTypewriterEffect() {
        // 清理已有计时器
        timer?.invalidate()
        
        // 重置显示索引
        displayedContentIndex = min(displayedContentIndex, message.content.count)
        
        // 创建新的计时器
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            if displayedContentIndex < message.content.count {
                displayedContentIndex += 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    // 返回当前应显示的内容
    private func visibleContent(from content: String) -> String {
        let index = min(displayedContentIndex, content.count)
        let visibleIndex = content.index(content.startIndex, offsetBy: index)
        return String(content[..<visibleIndex])
    }
    
    // 处理消息内容，确保合适的Markdown格式
    private func processMessageContent(_ content: String) -> String {
        var processedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果有检测到的URL链接但没有Markdown格式，自动转换为链接格式
        if !processedContent.contains("[") && !processedContent.contains("](") {
            for url in detectedLinks {
                let urlString = url.absoluteString
                if processedContent.contains(urlString) {
                    // 避免重复替换已经处理过的链接
                    if !processedContent.contains("[\(urlString)](\(urlString))") {
                        processedContent = processedContent.replacingOccurrences(
                            of: urlString,
                            with: "[\(urlString)](\(urlString))"
                        )
                    }
                }
            }
        }
        
        return processedContent
    }
    
    // 检测文本中的URL链接
    private func detectLinks(in text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        detectedLinks = matches?.compactMap { match -> URL? in
            if let url = match.url {
                return url
            }
            return nil
        } ?? []
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
    @Environment(\.colorScheme) var colorScheme
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// 新增上下文策略切换按钮
struct ContextStrategyButton: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingStrategyMenu = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            showingStrategyMenu = true
        }) {
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 14))
                Text("记忆")
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .foregroundColor(colorScheme == .dark ? .white : .primary)
            .cornerRadius(8)
        }
        .confirmationDialog("选择记忆策略", isPresented: $showingStrategyMenu, titleVisibility: .visible) {
            Button("最近消息") {
                viewModel.changeContextStrategy(.recentMessages)
            }
            
            Button("重要消息") {
                viewModel.changeContextStrategy(.importantMessages)
            }
            
            Button("摘要上下文") {
                viewModel.changeContextStrategy(.summarizedContext)
            }
        } message: {
            Text("选择AI回复时使用的记忆策略")
        }
    }
}

// 预览
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(AuthViewModel(previewMode: true))
            .environmentObject(ThemeManager())
    }
} 
