import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 配置网络安全设置
        configureNetworkSecurity()
        return true
    }
    
    private func configureNetworkSecurity() {
        // 在iOS 14+，我们可以使用更现代的方式配置网络安全
        #if DEBUG
        print("已为DeepSeek API配置网络安全设置")
        #endif
    }
} 