import Core
import Domain
import DSKit
import SwiftUI
import UIKit
import UserNotifications
import WebKit

public struct ProfileFeatureView: View {
    @State private var compound: ProfileFeatureCompound
    @State private var tempIsOn: Bool
    @State private var showPermissionAlert = false

    @Environment(\.openURL) private var openURL

    private let onShowAlert: (String) -> Void
    private let onProfileSetting: (String, String, Bool) -> Void
    private let onNotification: () -> Void
    private let onServiceTerms: () -> Void

    private let email = SupportEmail(
        toAddress: "poppang.app@gmail.com",
        title: "팝팡 문의사항",
        messageHeader: "문의사항을 입력해주세요."
    )
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    public init(
        userUuid: String = "demo-user",
        nickname: String = "홍길동",
        isAlerted: Bool = false,
        onShowAlert: @escaping (String) -> Void = { _ in },
        onProfileSetting: @escaping (String, String, Bool) -> Void = { _, _, _ in },
        onNotification: @escaping () -> Void = {},
        onServiceTerms: @escaping () -> Void = {}
    ) {
        let compound = ProfileFeatureCompound(
            userUuid: userUuid,
            nickname: nickname,
            isAlerted: isAlerted
        )
        _compound = State(wrappedValue: compound)
        _tempIsOn = State(wrappedValue: compound.state.isAlerted)
        self.onShowAlert = onShowAlert
        self.onProfileSetting = onProfileSetting
        self.onNotification = onNotification
        self.onServiceTerms = onServiceTerms
        Task { @MainActor in
            compound.preload()
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar {
                Text("마이페이지")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)

                Spacer()

                IconButton {
                    onShowAlert(compound.state.userUuid)
                }
            }

            VStack(spacing: 20) {
                NavigationButton(
                    title: compound.state.nickname,
                    buttonType: .navigation,
                    font: .bold,
                    size: 15
                ) {
                    onProfileSetting(
                        compound.state.userUuid,
                        compound.state.nickname,
                        compound.state.isAlerted
                    )
                }
                .padding(.horizontal, 24)

                Rectangle()
                    .fill(Color.mainGray5)
                    .frame(height: 2)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("키워드 알림")
                            .ppStyleFont(.scdream(.regular, size: 12))
                        Text("키워드의 팝업이 등록되면 안내해 드립니다.")
                            .ppStyleFont(.scdream(.light, size: 10))
                    }

                    Spacer()

                    Toggle("", isOn: $tempIsOn)
                        .labelsHidden()
                        .tint(.mainOrange)
                        .onChange(of: tempIsOn) { _, newValue in
                            handleToggleChange(newValue)
                        }
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "공지사항", buttonType: .navigation) {
                    onNotification()
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "문의하기", buttonType: .navigation) {
                    email.send(openURL: openURL)
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "서비스 이용약관", buttonType: .navigation) {
                    onServiceTerms()
                }
                .padding(.horizontal, 24)

                if let errorMessage = compound.state.errorMessage {
                    Text(errorMessage)
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainRed)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.top, 20)

            Spacer()

            HStack {
                Spacer()
                Text("버전: \(appVersion)")
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray2)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            compound.preload()
            tempIsOn = compound.state.isAlerted
        }
        .alert("알림 허용", isPresented: $showPermissionAlert) {
            Button("설정으로 이동") {
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url)
                else { return }
                UIApplication.shared.open(url)
            }
            Button("다음에 하기", role: .cancel) {}
        } message: {
            Text("팝업스토어 키워드 알림을 받으려면 알림 권한을 허용해 주세요.")
        }
    }

    private func handleToggleChange(_ newValue: Bool) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                DispatchQueue.main.async {
                    tempIsOn = false
                    showPermissionAlert = true
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            compound.send(.alertStatus(newValue))
                        } else {
                            tempIsOn = false
                            showPermissionAlert = true
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    compound.send(.alertStatus(newValue))
                }
            @unknown default:
                break
            }
        }
    }
}

public struct ProfileSettingFeatureView: View {
    @State private var compound: ProfileFeatureCompound
    @State private var showHardDeleteAlert = false
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let onLogout: () -> Void
    private let onNicknameUpdated: (String) -> Void

    public init(
        userUuid: String,
        nickname: String,
        isAlerted: Bool,
        onLogout: @escaping () -> Void = {},
        onNicknameUpdated: @escaping (String) -> Void = { _ in }
    ) {
        _compound = State(
            wrappedValue: ProfileFeatureCompound(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted
            )
        )
        self.onLogout = onLogout
        self.onNicknameUpdated = onNicknameUpdated
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedTextField(
                    placeholder: "닉네임을 입력해 주세요",
                    text: Binding(
                        get: { compound.state.newNickname },
                        set: { compound.send(.nicknameChanged($0)) }
                    ),
                    validationState: compound.state.validationState
                )
                .focused($isFocused)

                Button {
                    compound.send(.checkNewNickname)
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100, height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
            }

            validationMessage

            if let errorMessage = compound.state.errorMessage {
                Text(errorMessage)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            }

            Button {
                onLogout()
            } label: {
                Text("로그아웃")
                    .frame(height: 22)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.subBlack)
            }
            .padding(.top, 20)

            Button {
                showHardDeleteAlert = true
            } label: {
                Text("회원탈퇴")
                    .frame(height: 22)
                    .ppStyleFont(.scdream(.regular, size: 10))
                    .foregroundStyle(Color.mainGray2)
            }
            .padding(.top, 4)

            Spacer()

            MainOrangeButton(
                buttonTitle: "닉네임 변경",
                buttonColor: compound.state.validationState == .success ? Color.mainOrange : Color.mainGray2
            ) {
                compound.send(.updateNewNickname)
                UIApplication.shared.endEditing(true)
            }
            .disabled(compound.state.validationState != .success)
            .opacity(compound.state.validationState == .success ? 1.0 : 0.8)
            .padding(.bottom, 20)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("프로필 설정")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .padding(.top, 10)
            }
        }
        .onAppear {
            compound.send(.clearNickname)
            isFocused = true
        }
        .onChange(of: compound.state.didUpdateNickname) { _, didUpdate in
            guard didUpdate else { return }
            onNicknameUpdated(compound.state.nickname)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
        .onChange(of: compound.state.didDeleteUser) { _, didDelete in
            guard didDelete else { return }
            onLogout()
        }
        .alert("회원 탈퇴", isPresented: $showHardDeleteAlert) {
            Button("탈퇴하기", role: .destructive) {
                compound.send(.hardDeleteUser)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.")
        }
    }

    @ViewBuilder
    private var validationMessage: some View {
        if !compound.state.newNickname.isEmpty {
            switch compound.state.validationState {
            case .success:
                Text("사용 가능한 닉네임입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGreen)
                    .padding(.top, 5)
            case .duplicate:
                Text("이미 사용 중인 닉네임입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .invalidSpace:
                Text("공백은 사용할 수 없습니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .tooShort:
                Text("2글자 이하는 사용할 수 없습니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .checking:
                Text("확인 중입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .padding(.top, 5)
            default:
                EmptyView()
            }
        }
    }
}

public struct NotificationFeatureView: View {
    public init() {}

    public var body: some View {
        WebView(url: ExternalLinkConfig.notificationURL)
    }
}

public struct ServiceTermsFeatureView: View {
    public init() {}

    public var body: some View {
        WebView(url: ExternalLinkConfig.serviceTermsURL)
    }
}

private struct NavigationButton: View {
    enum ButtonType {
        case navigation
        case toggle
    }

    var title: String
    var subTitle: String?
    var buttonType: ButtonType
    var font: UIFont.SCDream
    var size: CGFloat
    var color: Color
    var action: () -> Void
    @Binding var isOn: Bool

    init(
        title: String,
        subTitle: String? = nil,
        buttonType: ButtonType,
        font: UIFont.SCDream = .regular,
        size: CGFloat = 12,
        color: Color = .subBlack,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subTitle = subTitle
        self.buttonType = buttonType
        self.font = font
        self.size = size
        self.color = color
        self.action = action
        self._isOn = .constant(false)
    }

    init(
        title: String,
        subTitle: String? = nil,
        buttonType: ButtonType,
        font: UIFont.SCDream = .regular,
        size: CGFloat = 12,
        color: Color = .subBlack,
        isOn: Binding<Bool>,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subTitle = subTitle
        self.buttonType = buttonType
        self.font = font
        self.size = size
        self.color = color
        self._isOn = isOn
        self.action = action
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .ppStyleFont(.scdream(font, size: size))

                if let subTitle {
                    Text(subTitle)
                        .ppStyleFont(.scdream(.light, size: 10))
                }
            }
            .foregroundStyle(color)

            Spacer()

            if buttonType == .navigation {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.mainOrange)
            }
        }
    }

    var body: some View {
        if buttonType == .navigation {
            Button(action: action) {
                content
            }
        } else {
            content
                .onChange(of: isOn) { _, _ in
                    action()
                }
        }
    }
}

private struct SupportEmail {
    let toAddress: String
    let title: String
    let messageHeader: String

    var body: String {
        """
        \(messageHeader)
    """
    }

    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("""
                This device does not support email
                \(body)
                """)
            }
        }
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        if let url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url, uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> WebCoordinator {
        WebCoordinator()
    }

    final class WebCoordinator: NSObject, WKNavigationDelegate {}
}
