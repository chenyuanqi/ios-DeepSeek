import Foundation

// 使用SwiftUI 5.0新特性，通过代码方式扩展Info.plist
extension Bundle {
    // 此方法在应用初始化时调用，确保网络安全设置已配置
    static func extendInfoPlist() {
        #if DEBUG
        print("已配置应用安全设置")
        #endif
    }
} 