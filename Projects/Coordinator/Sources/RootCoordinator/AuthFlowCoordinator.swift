import AuthenticationServices
import AuthFeature
import Core
import Domain
import SwiftUI

public struct AuthFlowDependencies {
    public var kakaoLogin: @MainActor () async throws -> User
    public var googleLogin: @MainActor () async throws -> User
    public var appleLogin: @MainActor (ASAuthorization) async throws -> User
    public var checkNickname: @MainActor (String) async throws -> Bool
    public var register: @MainActor (User) async throws -> User

    public init(
        kakaoLogin: @escaping @MainActor () async throws -> User,
        googleLogin: @escaping @MainActor () async throws -> User,
        appleLogin: @escaping @MainActor (ASAuthorization) async throws -> User,
        checkNickname: @escaping @MainActor (String) async throws -> Bool,
        register: @escaping @MainActor (User) async throws -> User
    ) {
        self.kakaoLogin = kakaoLogin
        self.googleLogin = googleLogin
        self.appleLogin = appleLogin
        self.checkNickname = checkNickname
        self.register = register
    }
}

@MainActor
public final class AuthFlowCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any RootCoordinating)?
    public var pendingRegistrationUser: User?
    private let dependencies: AuthFlowDependencies?

    public init(dependencies: AuthFlowDependencies? = nil) {
        self.dependencies = dependencies
        super.init()
    }

    public func makeRootView() -> some View {
        AuthFeatureView(
            kakaoLogin: dependencies?.kakaoLogin,
            googleLogin: dependencies?.googleLogin,
            appleLogin: dependencies?.appleLogin,
            onLoginSuccess: { [weak self] user in
                self?.parent?.completeAuthentication(user: user)
            }
        )
        .navigationTitle("Auth")
    }

    public func makeRegisterView() -> some View {
        RegisterFlowFeatureView(
            user: pendingRegistrationUser,
            checkNickname: dependencies?.checkNickname,
            register: dependencies?.register,
            onComplete: { [weak self] user in
                self?.pendingRegistrationUser = nil
                self?.parent?.completeAuthentication(userID: user.userUuid)
            }
        )
        .navigationTitle("Register")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
