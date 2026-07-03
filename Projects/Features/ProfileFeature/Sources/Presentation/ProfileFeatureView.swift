import ComposableArchitecture
import Core
import DSKit
import SwiftUI
import UIKit
import UserNotifications
import WebKit

public struct ProfileFeatureView: View {
    let store: StoreOf<ProfileFeature>
    @State private var showPermissionAlert = false

    @Environment(\.openURL) private var openURL

    private let email = SupportEmail(
        toAddress: "poppang.app@gmail.com",
        title: "팝팡 문의사항",
        messageHeader: "문의사항을 입력해주세요."
    )
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar {
                Text("마이페이지")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)

                Spacer()

                IconButton {
                    store.send(.alertTapped)
                }
            }

            VStack(spacing: 20) {
                NavigationButton(
                    title: store.nickname,
                    buttonType: .navigation,
                    font: .bold,
                    size: 15
                ) {
                    store.send(.profileSettingTapped)
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

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { store.localIsAlerted },
                            set: { handleToggleChange($0) }
                        )
                    )
                        .labelsHidden()
                        .tint(.mainOrange)
                        .disabled(store.isLoading)
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "공지사항", buttonType: .navigation) {
                    store.send(.notificationsTapped)
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "문의하기", buttonType: .navigation) {
                    email.send(openURL: openURL)
                }
                .padding(.horizontal, 24)

                NavigationButton(title: "서비스 이용약관", buttonType: .navigation) {
                    store.send(.serviceTermsTapped)
                }
                .padding(.horizontal, 24)

                if let errorMessage = store.errorMessage {
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
                    showPermissionAlert = true
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            store.send(.alertStatusChanged(newValue))
                        } else {
                            showPermissionAlert = true
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    store.send(.alertStatusChanged(newValue))
                }
            @unknown default:
                break
            }
        }
    }
}

public struct ProfileSettingFeatureView: View {
    let store: StoreOf<ProfileSettingFeature>
    @State private var showHardDeleteAlert = false
    @State private var draftNickname = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<ProfileSettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedTextField(
                    placeholder: "닉네임을 입력해 주세요",
                    text: $draftNickname,
                    validationState: store.validationState
                )
                .focused($isFocused)

                Button {
                    store.send(.validateNicknameTapped)
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100, height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
                .disabled(store.isLoading)
            }

            validationMessage

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            }

            Button {
                store.send(.logoutTapped)
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
                buttonColor: store.validationState == .success ? Color.mainOrange : Color.mainGray2
            ) {
                isFocused = false
                store.send(.updateNicknameTapped)
            }
            .disabled(store.validationState != .success || store.isLoading)
            .opacity(store.validationState == .success ? 1.0 : 0.8)
            .padding(.bottom, 20)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .ppBackNavigationBar(title: "프로필 설정") {
            isFocused = false
            dismiss()
        }
        .onAppear {
            draftNickname = store.newNickname
            isFocused = true
        }
        .onChange(of: draftNickname) { _, newValue in
            store.send(.nicknameChanged(newValue))
        }
        .alert("회원 탈퇴", isPresented: $showHardDeleteAlert) {
            Button("탈퇴하기", role: .destructive) {
                store.send(.hardDeleteTapped)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.")
        }
    }

    @ViewBuilder
    private var validationMessage: some View {
        if !store.newNickname.isEmpty {
            switch store.validationState {
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
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        WebView(url: ExternalLinkConfig.notificationURL)
            .ppBackNavigationBar(title: "공지사항") {
                dismiss()
            }
    }
}

public struct ServiceTermsFeatureView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        WebView(url: ExternalLinkConfig.serviceTermsURL)
            .ppBackNavigationBar(title: "서비스 이용약관") {
                dismiss()
            }
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
