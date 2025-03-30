import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部Logo
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .padding(.bottom, 10)
                        
                        Text("DeepSeek AI")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text(authViewModel.isRegistrationMode ? "创建账号，开启智能对话" : "欢迎回来")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // 错误信息
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 注册/登录表单
                    VStack(spacing: 16) {
                        // 用户名 (仅注册时显示)
                        if authViewModel.isRegistrationMode {
                            FormField(
                                icon: "person.fill",
                                placeholder: "用户名",
                                text: $authViewModel.username
                            )
                        }
                        
                        // 邮箱
                        FormField(
                            icon: "envelope.fill",
                            placeholder: "邮箱",
                            text: $authViewModel.email,
                            keyboardType: .emailAddress
                        )
                        
                        // 密码
                        PasswordField(
                            placeholder: "密码",
                            text: $authViewModel.password,
                            showPassword: $showPassword
                        )
                        
                        // 确认密码 (仅注册时显示)
                        if authViewModel.isRegistrationMode {
                            PasswordField(
                                placeholder: "确认密码",
                                text: $authViewModel.confirmPassword,
                                showPassword: $showConfirmPassword
                            )
                        }
                        
                        // 提交按钮
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.horizontal)
                    
                    // 切换登录/注册
                    Button(action: {
                        authViewModel.toggleRegistrationMode()
                    }) {
                        Text(authViewModel.isRegistrationMode ? "已有账号？点击登录" : "没有账号？点击注册")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    .disabled(authViewModel.isLoading)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
    }
}

// 表单输入组件
struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 密码输入组件
struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 24)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 预览
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel(previewMode: true))
    }
} 