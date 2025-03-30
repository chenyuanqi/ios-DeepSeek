import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isRegistering = false
    @State private var isShowingPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 徽标
                    VStack(spacing: 10) {
                        Image(systemName: "brain")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text("DeepSeek")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text(isRegistering ? "创建您的账户" : "欢迎回来")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    // 错误消息
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // 表单
                    VStack(spacing: 16) {
                        // 只在注册时显示用户名字段
                        if isRegistering {
                            FormField(
                                icon: "person.fill",
                                placeholder: "用户名",
                                text: $authViewModel.username
                            )
                        }
                        
                        FormField(
                            icon: "envelope.fill",
                            placeholder: "邮箱地址",
                            text: $authViewModel.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .none
                        )
                        
                        PasswordField(
                            placeholder: "密码",
                            text: $authViewModel.password,
                            isShowingPassword: $isShowingPassword
                        )
                        
                        // 确认密码字段仅在注册时显示
                        if isRegistering {
                            PasswordField(
                                placeholder: "确认密码",
                                text: $authViewModel.confirmPassword,
                                isShowingPassword: $isShowingPassword
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 登录/注册按钮
                    Button(action: {
                        if isRegistering {
                            authViewModel.register()
                        } else {
                            authViewModel.login()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text(isRegistering ? "注册" : "登录")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.horizontal)
                    
                    // 切换登录/注册模式
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            authViewModel.resetForm()
                        }
                    }) {
                        Text(isRegistering ? "已有账号？点击登录" : "没有账号？点击注册")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// 通用表单字段视图
struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .words
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .padding(.leading, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 密码输入字段
struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isShowingPassword: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isShowingPassword {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .padding(.leading, 8)
            } else {
                SecureField(placeholder, text: $text)
                    .padding(.leading, 8)
            }
            
            Button(action: {
                isShowingPassword.toggle()
            }) {
                Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 预览模式需要提供AuthViewModel
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
} 