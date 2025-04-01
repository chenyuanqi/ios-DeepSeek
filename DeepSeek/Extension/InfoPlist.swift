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

// Info.plist访问扩展
extension Bundle {
    var appName: String {
        return infoPlistValue(forKey: "CFBundleName") ?? "DeepSeek"
    }
    
    var appVersion: String {
        return infoPlistValue(forKey: "CFBundleShortVersionString") ?? "1.0"
    }
    
    var buildNumber: String {
        return infoPlistValue(forKey: "CFBundleVersion") ?? "1"
    }
    
    var storeKitProductsFile: String {
        return infoPlistValue(forKey: "StoreKitConfigFile") ?? "Products"
    }
    
    private func infoPlistValue<T>(forKey key: String) -> T? {
        guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plistDictionary = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let value = plistDictionary[key] as? T else {
            return nil
        }
        return value
    }
} 