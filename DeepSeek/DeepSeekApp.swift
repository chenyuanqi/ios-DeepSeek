//
//  DeepSeekApp.swift
//  DeepSeek
//
//  Created by yuanqi.chen on 2025/3/30.
//

import SwiftUI

// 设置全局网络权限
@available(iOS 14.0, *)
@main
struct DeepSeekApp: App {
    // 注册AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 如果需要，可以在这里添加初始化代码
    }
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .onAppear {
                    // 确保网络连接权限设置正确
                    #if DEBUG
                    print("DeepSeek应用已启动，网络请求已配置")
                    #endif
                }
        }
    }
}
