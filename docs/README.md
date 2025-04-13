# DeepSeek AI 应用开发文档

欢迎来到 DeepSeek AI 应用的开发文档。本文档集合提供了关于应用架构、功能实现和开发指南的详细信息，帮助开发者快速了解和参与项目。

## 文档索引

### 项目概述

- [项目结构说明](./project_structure.md) - 详细介绍项目的目录结构、核心组件和架构设计

### 核心功能实现

- [认证功能实现](./authentication.md) - 详细介绍用户注册、登录和会话管理的实现方式
- [API 集成文档](./api_integration.md) - 详细介绍 DeepSeek API 的集成和使用，包括标准请求和流式响应
- [订阅与 Apple Pay 指南（上）](./subscription_guide_part1.md) - 详细介绍会员订阅功能和 Apple Pay 的基础设置与配置
- [订阅与 Apple Pay 指南（下）](./subscription_guide_part2.md) - 详细介绍会员订阅的购买流程、Apple Pay 集成和状态管理
- [订阅与 Apple Pay 步骤指南](./subscription_step_by_step.md) - 简明扼要的步骤指南，重点关注苹果开发者网站和 Xcode 的具体配置流程
- [产品ID修复指南](./product_id_fix.md) - 解决项目中产品ID不一致问题的操作指南
- [Apple Pay 沙盒测试修复指南](./fix_apple_pay_sandbox.md) - 解决在模拟器中测试 Apple Pay 的相关问题
- [解决模拟器 Apple Pay 循环弹框](./fix_apple_pay_simulator.md) - 专门解决 Xcode 模拟器中 Apple Pay 授权框循环弹出的问题

### 后续计划添加的文档

- 主题系统实现 - 详细介绍深色模式和主题切换的实现
- Markdown 渲染实现 - 详细介绍 Markdown 内容的渲染与样式
- 对话记忆功能 - 详细介绍智能上下文管理和记忆策略实现

## 快速入门

如果您是新加入的开发者，建议按以下顺序了解项目：

1. 首先阅读 [项目结构说明](./project_structure.md) 了解整体架构
2. 然后阅读 [认证功能实现](./authentication.md) 了解用户系统
3. 接着阅读 [API 集成文档](./api_integration.md) 了解核心的聊天功能实现
4. 如需了解订阅功能，请直接阅读 [订阅与 Apple Pay 步骤指南](./subscription_step_by_step.md) 获取最简明的操作流程
5. **最新修复**：如果遇到产品ID不一致问题，请查看 [产品ID修复指南](./product_id_fix.md)
6. **Apple Pay测试**：如需在模拟器中测试 Apple Pay，请参考 [Apple Pay 沙盒测试修复指南](./fix_apple_pay_sandbox.md)
7. **模拟器问题**：如遇到模拟器中 Apple Pay 授权框循环弹出，请查看 [解决模拟器 Apple Pay 循环弹框](./fix_apple_pay_simulator.md)

## 贡献指南

我们欢迎所有开发者为项目做出贡献。如果您想参与开发，请遵循以下步骤：

1. Fork 主仓库
2. 创建您的功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启一个 Pull Request

## 开发环境设置

### 系统要求

- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本
- iOS 16.0+ 部署目标

### 安装步骤

1. 克隆仓库
   ```bash
   git clone https://github.com/your-username/DeepSeek.git
   ```

2. 打开项目
   ```bash
   cd DeepSeek
   open DeepSeek.xcodeproj
   ```

3. 安装依赖（如果使用 CocoaPods 或 Swift Package Manager）

4. 构建并运行项目

## 联系我们

如果您有任何问题或建议，请通过以下方式联系我们：

- 提交 GitHub Issue
- 发送邮件到 support@deepseek-example.com（示例邮箱） 