import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    // 主题模式
    enum ThemeMode: String, CaseIterable {
        case system = "跟随系统"
        case light = "浅色模式"
        case dark = "深色模式"
    }
    
    // 当前主题模式
    @Published var currentThemeMode: ThemeMode {
        didSet {
            // 保存到UserDefaults
            UserDefaults.standard.set(currentThemeMode.rawValue, forKey: "themeMode")
            updateColorScheme()
        }
    }
    
    // 颜色方案，用于绑定到视图的preferredColorScheme
    @Published var colorScheme: ColorScheme?
    
    // 系统颜色方案
    @Published var systemColorScheme: ColorScheme = .light
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 从UserDefaults读取设置，如果没有则默认为system
        let savedTheme = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.system.rawValue
        self.currentThemeMode = ThemeMode.allCases.first { $0.rawValue == savedTheme } ?? .system
        
        // 初始化颜色方案
        updateColorScheme()
        
        // 监听系统颜色方案变化（如果有外部发布者）
        NotificationCenter.default.publisher(for: Notification.Name("systemAppearanceChanged"))
            .sink { [weak self] _ in
                self?.updateColorScheme()
            }
            .store(in: &cancellables)
    }
    
    // 更新颜色方案
    private func updateColorScheme() {
        switch currentThemeMode {
        case .system:
            colorScheme = nil  // nil表示跟随系统
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
        
        print("🎨 主题已切换为: \(currentThemeMode.rawValue)")
    }
    
    // 切换主题
    func setThemeMode(_ mode: ThemeMode) {
        guard currentThemeMode != mode else { return }
        currentThemeMode = mode
    }
    
    // 获取深色模式状态（判断当前是否处于深色模式）
    func isDarkMode(in environment: EnvironmentValues) -> Bool {
        switch currentThemeMode {
        case .system:
            return environment.colorScheme == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    // 便捷方法 - 获取适配深色模式的颜色
    func adaptiveColor(light: Color, dark: Color, in environment: EnvironmentValues) -> Color {
        return isDarkMode(in: environment) ? dark : light
    }
} 