//
//  DeepSeekApp.swift
//  DeepSeek
//
//  Created by yuanqi.chen on 2025/3/30.
//

import SwiftUI

// 添加AppConfiguration
struct AppConfiguration {
    static var useMockAPI: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "useMockAPI")
        #else
        return false
        #endif
    }
    
    static func toggleMockAPI() {
        #if DEBUG
        let current = UserDefaults.standard.bool(forKey: "useMockAPI")
        UserDefaults.standard.set(!current, forKey: "useMockAPI")
        print("🔄 Mock API模式已\(!current ? "开启" : "关闭")")
        #endif
    }
}

// 设置全局网络权限
@available(iOS 14.0, *)
@main
struct DeepSeekApp: App {
    // 注册AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 认证视图模型
    @StateObject private var authViewModel: AuthViewModel
    
    // 主题管理器
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // 配置网络请求和日志
        print("🚀 应用启动: DeepSeek")
        print("📱 系统版本: \(UIDevice.current.systemVersion)")
        
        #if DEBUG
        print("🧪 当前为DEBUG模式")
        #endif
        
        // 检查是否使用模拟API
        #if DEBUG
        if ProcessInfo.processInfo.environment["MOCK_API"] == "1" {
            _authViewModel = StateObject(wrappedValue: AuthViewModel(previewMode: true))
            print("🧪 应用启动于模拟API模式")
        } else {
            _authViewModel = StateObject(wrappedValue: AuthViewModel())
        }
        #else
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        #endif
        
        print("网络请求已配置")
    }
    
    var body: some Scene {
        WindowGroup {
            // 始终先显示主页内容，在后台进行身份验证检查
            AppContentView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                #if DEBUG
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !authViewModel.isAuthenticated {
                            Button(action: {
                                // 切换模拟API模式
                                let newValue = !(ProcessInfo.processInfo.environment["MOCK_API"] == "1")
                                setenv("MOCK_API", newValue ? "1" : "0", 1)
                                // 添加延迟重启
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    exit(0)
                                }
                            }) {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                #endif
        }
    }
}

// 新增的ContentView，用于管理登录状态和视图切换
struct AppContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isCheckingAuth = true
    
    var body: some View {
        ZStack {
            // 先显示聊天视图
            ChatView()
                .environmentObject(authViewModel)
                .opacity(authViewModel.isAuthenticated ? 1 : 0)
            
            // 在需要时才显示登录视图
            if !authViewModel.isAuthenticated && !isCheckingAuth {
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // 在视图加载后检查登录状态
            checkAuthWithDelay()
        }
    }
    
    // 添加延迟检查，给用户一个平滑的体验
    private func checkAuthWithDelay() {
        // 设置检查状态
        isCheckingAuth = true
        
        // 开始检查认证状态
        authViewModel.checkAuthState()
        
        // 添加短暂延迟，保证UI平滑过渡
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                isCheckingAuth = false
            }
        }
    }
}
