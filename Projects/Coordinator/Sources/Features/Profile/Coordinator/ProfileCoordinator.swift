import AlertFeature
import Core
import ProfileFeature
import SwiftUI
import WebKit

@MainActor
public protocol ProfileCoordinatorParent: AnyObject {
    func logout()
}

@MainActor
public final class ProfileCoordinator: Coordinator<
    ProfileFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any ProfileCoordinatorParent)?

    public func makeRootView() -> some View {
        ProfileFeatureView(onLogout: { [weak self] in
            self?.parent?.logout()
        })
        .navigationTitle("Profile")
    }

    @ViewBuilder
    public func buildView(for route: ProfileFeatureRoute) -> some View {
        switch route {
        case .alert:
            AlertFeatureView()
        case .profileSetting:
            ProfileSettingScreen()
        case .notifications:
            NotificationsScreen()
        case .serviceTerms:
            ServiceTermsScreen()
        }
    }
}

private struct ProfileSettingScreen: View {
    var body: some View {
        Form {
            Section("프로필 설정") {
                LabeledContent("닉네임", value: "modular-user")
                LabeledContent("계정 상태", value: "정상")
            }
        }
        .navigationTitle("프로필 설정")
    }
}

private struct NotificationsScreen: View {
    var body: some View {
        WebContentView(url: ExternalLinkConfig.notificationURL)
        .navigationTitle("공지사항")
    }
}

private struct ServiceTermsScreen: View {
    var body: some View {
        WebContentView(url: ExternalLinkConfig.serviceTermsURL)
        .navigationTitle("서비스 이용약관")
    }
}

private struct WebContentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> WebCoordinator {
        WebCoordinator()
    }

    final class WebCoordinator: NSObject, WKNavigationDelegate {}
}
