import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isSecured: Bool = true
    @State private var isConfirmSecured: Bool = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo部分
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color("AdaptiveAccent"))
                        
                        Text("DeepSeek")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("AdaptiveText"))
                        
                        Text(authViewModel.isRegistrationMode ? "创建账号，开始对话" : "欢迎回来")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AdaptiveSecondary"))
                    }
                    .padding(.top, 40)
                    
                    // 错误消息
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    // 表单部分
                    VStack(spacing: 20) {
                        if authViewModel.isRegistrationMode {
                            // 用户名字段（只在注册模式显示）
                            FormField(
                                icon: "person.fill",
                                placeholder: "用户名",
                                text: $authViewModel.username
                            )
                        }
                        
                        // 邮箱字段
                        FormField(
                            icon: "envelope.fill",
                            placeholder: "邮箱",
                            text: $authViewModel.email,
                            keyboardType: .emailAddress
                        )
                        
                        // 密码字段
                        PasswordField(
                            placeholder: "密码",
                            text: $authViewModel.password,
                            isSecured: $isSecured
                        )
                        
                        if authViewModel.isRegistrationMode {
                            // 确认密码字段（只在注册模式显示）
                            PasswordField(
                                placeholder: "确认密码",
                                text: $authViewModel.confirmPassword,
                                isSecured: $isConfirmSecured
                            )
                        }
                        
                        // 登录/注册按钮
                        Button(action: {
                            if authViewModel.isRegistrationMode {
                                authViewModel.register()
                            } else {
                                authViewModel.login()
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                }
                                
                                Text(authViewModel.isRegistrationMode ? "注册" : "登录")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AdaptiveAccent"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(authViewModel.isLoading)
                        
                        // 切换注册/登录模式
                        Button(action: {
                            withAnimation {
                                authViewModel.isRegistrationMode.toggle()
                                authViewModel.resetForm()
                            }
                        }) {
                            Text(authViewModel.isRegistrationMode ? "已有账号？点击登录" : "没有账号？点击注册")
                                .foregroundColor(Color("AdaptiveAccent"))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color("AdaptiveBackground").edgesIgnoringSafeArea(.all))
        }
    }
}

// 表单字段组件
struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AdaptiveSecondary"))
                .frame(width: 30)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// 密码字段组件
struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isSecured: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(Color("AdaptiveSecondary"))
                .frame(width: 30)
            
            if isSecured {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(Color("AdaptiveSecondary"))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(AuthViewModel(previewMode: true))
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
            
            LoginView()
                .environmentObject(AuthViewModel(previewMode: true))
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
        }
    }
} 