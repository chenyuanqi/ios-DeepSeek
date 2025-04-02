import SwiftUI
import StoreKit

struct MembershipView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: MembershipViewModel
    @State private var selectedPlan: MembershipViewModel.MembershipPlan = .monthly
    @State private var showSuccessAlert = false
    @State private var showCancelConfirmation = false
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 顶部标题
                    headerView
                    
                    // 会员信息（如果已订阅）
                    if viewModel.isMember {
                        memberInfoView
                    } else {
                        // StoreKit加载状态
                        if viewModel.storeManager.products.isEmpty && viewModel.storeManager.isLoading {
                            // 加载中
                            loadingView
                        } else if viewModel.storeManager.products.isEmpty && !viewModel.storeManager.error.isNilOrEmpty {
                            // 加载失败
                            storeErrorView
                        } else {
                            // 会员特权
                            privilegesView
                            
                            // 开发模式提示
                            #if DEBUG
                            if viewModel.storeManager.products.isEmpty {
                                developmentModeNotice
                            }
                            #endif
                            
                            // 套餐选择
                            plansView
                            
                            // 支付方式选择
                            paymentMethodView
                            
                            // 订阅按钮
                            subscribeButton
                            
                            // 恢复购买按钮
                            restorePurchasesButton
                        }
                    }
                    
                    // 说明文本
                    footerView
                }
                .padding()
            }
            .background(Color("AdaptiveBackground").edgesIgnoringSafeArea(.all))
            .navigationBarTitle("会员订阅", displayMode: .inline)
            .navigationBarItems(trailing: 
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            )
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("订阅成功"),
                    message: Text("您已成功订阅\(selectedPlan.displayName)会员"),
                    dismissButton: .default(Text("确定")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .actionSheet(isPresented: $showCancelConfirmation) {
                ActionSheet(
                    title: Text("取消订阅"),
                    message: Text("您确定要取消会员订阅吗？取消后将立即失去会员权益。"),
                    buttons: [
                        .destructive(Text("确认取消")) {
                            cancelSubscription()
                        },
                        .cancel(Text("再想想"))
                    ]
                )
            }
            .alert("恢复购买", isPresented: $showRestoreAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                if restoreSuccess {
                    Text("已成功恢复您的购买")
                } else {
                    Text("未找到可恢复的购买")
                }
            }
            .onAppear {
                viewModel.checkMembershipStatus()
            }
        }
    }
    
    // 开发模式提示
    #if DEBUG
    private var developmentModeNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("开发模式")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
            }
            
            Text("当前处于开发模式，StoreKit配置未生效。实际购买功能将在真实App Store环境中测试。")
                .font(.system(size: 14))
                .foregroundColor(Color("AdaptiveSecondary"))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .padding(.vertical, 8)
    }
    #endif
    
    // 顶部标题部分
    private var headerView: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.yellow)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .clipShape(Circle())
            
            Text("元气大宝VIP")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("AdaptiveText"))
            
            if viewModel.isMember {
                Text("您已是\(viewModel.currentPlan?.displayName ?? "")用户")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            } else {
                Text("解锁所有高级功能，提升AI体验")
                    .font(.system(size: 16))
                    .foregroundColor(Color("AdaptiveSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // 加载状态视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("正在加载产品信息...")
                .font(.system(size: 16))
                .foregroundColor(Color("AdaptiveSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    // 加载错误视图
    private var storeErrorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .padding()
            
            Text("加载产品信息失败")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color("AdaptiveText"))
            
            if let error = viewModel.storeManager.error {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(Color("AdaptiveSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.storeManager.loadProducts()
                }
            }) {
                Text("重试")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // 会员信息视图（已订阅时显示）
    private var memberInfoView: some View {
        VStack(spacing: 20) {
            if let plan = viewModel.currentPlan, let expirationDate = viewModel.expirationDate {
                VStack(alignment: .leading, spacing: 16) {
                    Text("会员信息")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color("AdaptiveText"))
                    
                    HStack {
                        Image(systemName: "person.fill.checkmark")
                            .foregroundColor(.green)
                        Text("当前套餐：\(plan.displayName)")
                            .foregroundColor(Color("AdaptiveText"))
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        
                        Text("到期日期：\(expirationDateFormatted(expirationDate))")
                            .foregroundColor(Color("AdaptiveText"))
                        Spacer()
                    }
                    
                    if let remainingDays = viewModel.getRemainingDays() {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("剩余天数：\(remainingDays)天")
                                .foregroundColor(Color("AdaptiveText"))
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color("AdaptiveSecondaryBackground"))
                .cornerRadius(12)
                
                // 取消订阅按钮
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("管理订阅")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.red)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
                .disabled(viewModel.isLoading)
                .padding(.vertical)
            }
        }
    }
    
    // 会员特权部分
    private var privilegesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("会员特权")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("AdaptiveText"))
            
            PrivilegeRow(icon: "speedometer", title: "无限使用次数", description: "每天不限次数使用AI对话")
            PrivilegeRow(icon: "bolt.fill", title: "高级AI模型", description: "优先使用最新的模型进行对话")
            PrivilegeRow(icon: "photo.fill", title: "图片生成", description: "支持生成高质量AI图片")
            PrivilegeRow(icon: "paperclip", title: "文件上传分析", description: "上传文件进行AI分析")
            PrivilegeRow(icon: "clock.fill", title: "优先响应", description: "高峰期优先获得响应")
        }
        .padding()
        .background(Color("AdaptiveSecondaryBackground"))
        .cornerRadius(12)
    }
    
    // 套餐选择部分
    private var plansView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择套餐")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("AdaptiveText"))
            
            // 使用StoreKit产品
            if viewModel.storeManager.products.isEmpty {
                // 如果没有StoreKit产品，使用模拟产品
                VStack(spacing: 8) {
                    MockPlanCard(
                        plan: .monthly,
                        isSelected: selectedPlan == .monthly,
                        action: { selectedPlan = .monthly }
                    )
                    
                    MockPlanCard(
                        plan: .quarterly,
                        isSelected: selectedPlan == .quarterly,
                        action: { selectedPlan = .quarterly }
                    )
                    
                    MockPlanCard(
                        plan: .yearly,
                        isSelected: selectedPlan == .yearly,
                        action: { selectedPlan = .yearly }
                    )
                }
            } else {
                // 使用真实StoreKit产品
                ForEach(viewModel.storeManager.products, id: \.id) { product in
                    if let plan = MembershipViewModel.MembershipPlan.fromProductID(product.id) {
                        StoreProductView(
                            product: product,
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            action: { selectedPlan = plan }
                        )
                    }
                }
            }
        }
    }
    
    // 支付方式选择
    private var paymentMethodView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支付方式")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("AdaptiveText"))
            
            HStack(spacing: 12) {
                // 标准IAP支付
                PaymentMethodCard(
                    title: "App Store",
                    icon: "creditcard",
                    isSelected: viewModel.selectedPaymentMethod == .inAppPurchase,
                    action: { viewModel.selectedPaymentMethod = .inAppPurchase }
                )
                
                // Apple Pay支付
                PaymentMethodCard(
                    title: "Apple Pay",
                    icon: "apple.logo",
                    isSelected: viewModel.selectedPaymentMethod == .applePay,
                    isDisabled: !viewModel.storeManager.applePaySupported,
                    action: { 
                        if viewModel.storeManager.applePaySupported {
                            viewModel.selectedPaymentMethod = .applePay
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }
    
    // 订阅按钮
    private var subscribeButton: some View {
        Button(action: {
            subscribe()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                
                // 根据选择的支付方式显示不同的按钮文字
                if viewModel.selectedPaymentMethod == .applePay {
                    Text("使用Apple Pay订阅")
                        .fontWeight(.semibold)
                } else {
                    Text("立即订阅")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.selectedPaymentMethod == .applePay ? Color.black : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .padding(.vertical, 8)
    }
    
    // 恢复购买按钮
    private var restorePurchasesButton: some View {
        Button(action: {
            restorePurchases()
        }) {
            Text("恢复已购买的项目")
                .font(.system(size: 14))
                .foregroundColor(.blue)
        }
        .disabled(viewModel.isLoading)
        .padding(.bottom, 8)
    }
    
    // 底部说明文本
    private var footerView: some View {
        VStack(spacing: 8) {
            Text("订阅说明")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("AdaptiveText"))
            
            Text("• 订阅会在到期前24小时自动续费\n• 可随时在Apple ID设置中关闭自动续费\n• 所有价格均包含适用税费")
                .font(.system(size: 12))
                .foregroundColor(Color("AdaptiveSecondary"))
                .multilineTextAlignment(.center)
            
            #if DEBUG
            // 开发模式下的额外说明
            if viewModel.storeManager.products.isEmpty {
                Text("当前为开发模式，显示的价格为模拟数据")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
            #endif
        }
        .padding()
    }
    
    // 订阅操作
    private func subscribe() {
        viewModel.subscribe(plan: selectedPlan) { success in
            if success {
                showSuccessAlert = true
            }
        }
    }
    
    // 恢复购买操作
    private func restorePurchases() {
        viewModel.restorePurchases { success in
            restoreSuccess = success
            showRestoreAlert = true
        }
    }
    
    // 取消订阅操作
    private func cancelSubscription() {
        viewModel.cancelSubscription { _ in
            // 不管成功与否，都不自动关闭页面，用户需要关闭弹窗查看错误信息
        }
    }
    
    // 格式化日期
    private func expirationDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// 模拟计划卡片（不使用StoreKit产品时使用）
struct MockPlanCard: View {
    let plan: MembershipViewModel.MembershipPlan
    let isSelected: Bool
    let action: () -> Void
    
    // 获取价格 - 硬编码确保价格正确显示
    private var price: String {
        switch plan {
        case .monthly:
            return "¥28/月"
        case .quarterly:
            return "¥78/季"
        case .yearly:
            return "¥238/年"
        }
    }
    
    // 获取折扣 - 硬编码确保折扣正确显示
    private var discount: String? {
        switch plan {
        case .monthly:
            return nil
        case .quarterly:
            return "减¥6"
        case .yearly:
            return "减¥98"
        }
    }
    
    // 获取颜色
    private var color: Color {
        switch plan {
        case .monthly:
            return .blue
        case .quarterly:
            return .purple
        case .yearly:
            return .orange
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.displayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("AdaptiveText"))
                    
                    Text(price)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let discount = discount {
                    Text(discount)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color)
                        .cornerRadius(8)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : Color("AdaptiveSecondary"))
                    .font(.system(size: 22))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color("AdaptiveSecondary").opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// StoreKit产品视图
struct StoreProductView: View {
    let product: Product
    let plan: MembershipViewModel.MembershipPlan
    let isSelected: Bool
    let action: () -> Void
    
    // 获取折扣 - 硬编码确保折扣正确显示
    private var discount: String? {
        switch plan {
        case .monthly:
            return nil
        case .quarterly:
            return "减¥6"
        case .yearly:
            return "减¥98"
        }
    }
    
    // 获取颜色
    private var color: Color {
        switch plan {
        case .monthly:
            return .blue
        case .quarterly:
            return .purple
        case .yearly:
            return .orange
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.displayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("AdaptiveText"))
                    
                    Text(getPriceForPlan())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let discount = discount {
                    Text(discount)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color)
                        .cornerRadius(8)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : Color("AdaptiveSecondary"))
                    .font(.system(size: 22))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color("AdaptiveSecondary").opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 获取硬编码价格
    private func getPriceForPlan() -> String {
        switch plan {
        case .monthly:
            return "¥28/月"
        case .quarterly:
            return "¥78/季"
        case .yearly:
            return "¥238/年"
        }
    }
}

// 特权行组件
struct PrivilegeRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("AdaptiveText"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color("AdaptiveSecondary"))
            }
            
            Spacer()
        }
    }
}

// 添加支付方式选择卡片组件
struct PaymentMethodCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : (isDisabled ? .gray : Color("AdaptiveText")))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : (isDisabled ? .gray : Color("AdaptiveText")))
                
                if isDisabled {
                    Text("不可用")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color("AdaptiveSecondaryBackground"))
                    .opacity(isDisabled ? 0.5 : 1)
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - 扩展方法
extension String? {
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
}

// 预览
struct MembershipView_Previews: PreviewProvider {
    static var previews: some View {
        MembershipView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel(previewMode: true))
            .environmentObject(MembershipViewModel())
    }
} 