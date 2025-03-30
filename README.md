# DeepSeek AI 聊天应用

这是一个仿 DeepSeek AI 官方应用的聊天界面实现，使用 SwiftUI 开发，并集成了 DeepSeek AI API。

## 功能特性

1. **用户认证系统**
   - 支持基于邮箱的注册和登录
   - 登录状态持久化存储
   - 密码安全显示和隐藏切换
   - 表单验证和错误提示
   - 用户个人资料管理

2. **聊天功能**
   - 用户可以输入消息并获得实时 AI 回复
   - 支持消息气泡展示，区分用户和 AI 消息
   - 支持默认提示问题的快速发送
   - 集成 DeepSeek API 提供真实的 AI 回复
   - **实时流式响应**：AI回复实时展示，一边请求一边显示结果
   - **打字效果**：带有打字光标动画，提供更加自然的交互体验
   - **模型切换**：支持在常规模式和深度思考模式之间切换

3. **聊天历史记录**
   - 自动保存对话历史
   - 按日期分组展示历史对话
   - 支持对话查询和删除
   - **精确时间显示**：显示每次对话的具体时间（如今天 15:30）
   - **对话预览**：点击历史记录可展开查看对话内容预览
   - **快速访问**：可直接从预览跳转到完整对话

4. **用户体验增强**
   - 思考动画：AI回复前显示动态"思考中"提示
   - 响应格式优化：确保无空行，更好的显示效果
   - 详细日志记录：便于开发者调试
   - 网络错误处理：友好的错误提示
   - **功能提示**：未实现功能（如联网）点击时显示友好提示
   - **流畅滚动**：接收流式响应时自动平滑滚动到最新内容

5. **用户界面**
   - 符合 iOS 设计规范的用户界面
   - 加载状态和错误处理
   - 流畅的动画和交互效果
   - 支持自适应布局

## 项目结构

项目采用 MVVM 架构模式组织代码：

- **Views**: 包含所有视图组件
  - `LoginView.swift`: 登录注册界面
  - `ChatView.swift`: 主聊天界面
  - `ChatHistoryView.swift`: 聊天历史记录界面
  - 其他自定义组件

- **ViewModels**: 包含业务逻辑
  - `AuthViewModel.swift`: 管理认证状态和用户信息
  - `ChatViewModel.swift`: 管理聊天和历史记录

- **Models**: 包含数据模型
  - `User.swift`: 用户模型和认证错误类型
  - `Message.swift`: 定义消息和对话数据结构

- **Services**: 包含服务层
  - `APIService.swift`: 处理与 DeepSeek API 的通信，支持标准请求和流式请求

- **Extension**: 包含Swift扩展
  - `InfoPlist.swift`: App配置文件扩展

## API 集成

应用集成了 DeepSeek API，通过 API 来获取 AI 回复：

- 使用 Combine 框架处理异步网络请求
- 实现错误处理和加载状态显示
- 支持多轮对话
- **增强的流式响应**：使用自定义 Publisher 和 Subscription 实现逐字显示效果，实时更新UI
- **模型切换**：支持在DeepSeek-V3和DeepSeek-R1模型间切换

## 网络请求日志

应用实现了详细的API请求日志记录功能：

1. **请求日志**：记录请求开始、请求体大小和使用模型等信息
2. **网络连接状态**：记录连接状态和错误信息
3. **HTTP响应**：记录HTTP状态码和内容大小
4. **数据解析**：记录数据流解析过程和结果
5. **错误处理**：详细的错误日志记录和用户友好的错误提示
6. **流式数据跟踪**：详细记录流式数据接收和处理过程

## 用户认证功能

为提供安全的用户体验：

1. **登录界面**：提供电子邮件和密码输入
2. **注册功能**：自动切换到注册模式，收集用户名、邮箱和密码
3. **密码安全**：支持密码显示/隐藏切换，确保安全输入
4. **表单验证**：所有字段的实时验证和错误提示
5. **个性化欢迎**：登录后显示个性化欢迎信息
6. **用户菜单**：支持查看个人资料和退出登录
7. **安全存储**：使用UserDefaults安全存储登录状态

## 用户等待体验优化

为了提升用户等待AI回复的体验：

1. **动态思考提示**：随机显示不同的思考提示，如"正在思考"、"深入分析中"等
2. **点状动画**：思考提示末尾的点数动态变化，增强视觉反馈
3. **平滑过渡**：从等待状态到收到第一个响应块时的平滑过渡
4. **进度指示器**：在等待过程中显示活动指示器
5. **显示优化**：优化消息内容显示，确保无前导空行，提升阅读体验

## 流式响应优化

为提供更自然的对话体验：

1. **实时显示**：一边接收API响应一边更新UI，无需等待完整响应
2. **逐字显示**：模拟真人打字效果，文字逐个显示
3. **打字光标**：在文本末尾显示闪烁的打字光标
4. **自动滚动**：接收新内容时自动平滑滚动到最新位置
5. **详细日志**：记录每个内容块的接收与处理过程
6. **错误处理**：增强的错误处理和内容验证机制

## 聊天历史记录优化

为提供更好的历史对话浏览体验：

1. **对话标题**：使用用户的第一条消息作为对话标题，方便识别对话内容
2. **详细时间显示**：显示对话发生的具体时间（如"今天 15:30"、"昨天 09:45"）
3. **消息数量指示**：显示每个对话包含的消息数量
4. **对话预览功能**：
   - 点击对话可展开查看部分消息内容
   - 展开视图中区分用户和AI消息，并显示发送者图标
   - 长对话提供"查看完整对话"按钮
5. **快速操作**：提供"继续对话"按钮，方便快速回到之前的对话

## 使用方法

1. **注册和登录**
   - 首次使用时，输入邮箱、用户名和密码注册账号
   - 已有账号时，使用邮箱和密码登录
   - 通过右上角的用户图标菜单可退出登录

2. **发送消息**
   - 在底部输入框中输入内容并点击发送按钮
   - 或点击预设问题直接发送
   - 享受 AI 实时流式回复的打字机效果

3. **查看历史记录**
   - 点击左上角菜单按钮打开历史记录
   - 可搜索或按时间查看历史对话
   - 点击对话行可展开查看对话内容预览
   - 点击"继续对话"或"查看完整对话"进入完整对话界面

4. **模型切换**
   - 点击底部"RI • 深度思考"按钮切换模型
   - 蓝色状态表示启用深度思考模式(R1模型)
   - 灰色状态表示使用标准模式(V3模型)

## 最近更新

1. **添加用户认证系统**：实现登录注册功能，支持用户个人资料管理
2. **增强流式响应**：优化流式响应处理，确保实时显示AI回复
3. **增强历史记录功能**：添加对话预览、详细时间和用户问题标题展示
4. **功能提示系统**：为未实现功能添加友好提示
5. **修复启动问题**：解决应用启动时显示"Hello, World"而不是聊天界面的问题
6. **增强API日志**：添加详细的API请求和响应日志，便于开发者调试
7. **优化用户等待体验**：添加动态思考提示和动画效果
8. **模型切换功能**：支持在不同的DeepSeek模型之间切换

## 未来改进计划

1. ~~添加流式响应支持（Stream API）~~ **已实现**
2. ~~添加模型切换功能~~ **已实现**
3. ~~优化用户等待体验~~ **已实现**
4. ~~增强历史记录功能~~ **已实现**
5. ~~优化流式响应体验~~ **已实现**
6. ~~添加用户认证系统~~ **已实现**
7. 添加语音输入功能
8. 支持图片和文件的发送和接收
9. 增强对话记忆能力
10. 实现本地模型运行 