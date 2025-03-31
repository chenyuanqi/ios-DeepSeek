import SwiftUI

struct ProfileEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var nickname: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("个人信息")) {
                    TextField("昵称", text: $nickname)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: {
                        updateProfile()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("保存")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("修改个人资料")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: EmptyView()
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("提示"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .onAppear {
                // 加载当前用户昵称
                if let currentUser = authViewModel.currentUser {
                    nickname = currentUser.nickname
                }
            }
        }
    }
    
    private func updateProfile() {
        // 表单验证
        guard !nickname.isEmpty else {
            alertMessage = "昵称不能为空"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // 调用AuthViewModel中的方法更新用户信息
        authViewModel.updateUserProfile(nickname: nickname) { success, message in
            isLoading = false
            
            if success {
                // 更新成功，关闭编辑界面
                presentationMode.wrappedValue.dismiss()
            } else {
                // 显示错误消息
                alertMessage = message ?? "更新失败"
                showAlert = true
            }
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditView()
            .environmentObject(AuthViewModel(previewMode: true))
    }
} 