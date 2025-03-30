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
    
    // 创建并注入视图模型
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        // 检查是否使用模拟API
        #if DEBUG
        let useMockAPI = AppConfiguration.useMockAPI
        _authViewModel = StateObject(wrappedValue: AuthViewModel(previewMode: useMockAPI))
        if useMockAPI {
            print("🧪 应用启动于模拟API模式")
        }
        #else
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        #endif
        
        print("网络请求已配置")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthenticated {
                    // 用户已登录，显示聊天界面
                    ChatView()
                        .environmentObject(authViewModel)
                } else {
                    // 用户未登录，显示登录界面
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                authViewModel.checkAuthState()
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        AppConfiguration.toggleMockAPI()
                        // 显示提示重新启动应用
                        let alert = UIAlertController(
                            title: "切换API模式", 
                            message: "已切换\(AppConfiguration.useMockAPI ? "到模拟API" : "到真实API")模式，请重启应用使设置生效", 
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "确定", style: .default))
                        
                        // 获取当前窗口的根控制器（适用于iOS 15及以上版本）
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootController = windowScene.windows.first?.rootViewController {
                            rootController.present(alert, animated: true)
                        }
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                    }
                }
            }
            #endif
        }
    }
}
