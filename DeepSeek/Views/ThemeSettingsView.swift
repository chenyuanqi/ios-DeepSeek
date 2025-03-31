import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("主题切换")) {
                    Picker("显示模式", selection: $themeManager.currentThemeMode) {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Text("当前模式")
                        Spacer()
                        Text(themeManager.currentThemeMode.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("预览"), footer: Text("选择模式后会立即应用")) {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AdaptiveBackground"))
                            .frame(height: 60)
                            .overlay(
                                Text("背景颜色")
                                    .foregroundColor(Color("AdaptiveText"))
                            )
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AdaptiveAccent"))
                            .frame(height: 60)
                            .overlay(
                                Text("强调色")
                                    .foregroundColor(.white)
                            )
                        
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AdaptiveText"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("文本")
                                        .foregroundColor(Color("AdaptiveBackground"))
                                )
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AdaptiveSecondary"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("次要")
                                        .foregroundColor(Color("AdaptiveText"))
                                )
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("蓝色")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("主题切换")
            .navigationBarItems(
                leading: Button("返回") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.light)
        
        ThemeSettingsView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
} 