import Coordinator
import Core
import Foundation

struct AppBootstrap {
    let sessionStorage: AppSessionStorage
    let launchStateResolver: AppLaunchStateResolver
    let dependencies: AppDependencyRegistry

    static func live(
        store: KeyValueStoring = UserDefaultsStore()
    ) -> AppBootstrap {
        AppBootstrap(
            sessionStorage: AppSessionStorage(store: store),
            launchStateResolver: AppLaunchStateResolver(),
            dependencies: .live()
        )
    }

    @MainActor
    func makeRootCoordinator() -> RootCoordinator {
        let snapshot = sessionStorage.loadSnapshot()
        let nextDestination = launchStateResolver.resolve(snapshot: snapshot)
        let actions = RootCoordinatorActions(
            completeOnboarding: {
                sessionStorage.setOnboardingCompleted(true)
            },
            authenticate: { userID in
                sessionStorage.setOnboardingCompleted(true)
                sessionStorage.saveUserID(userID)
            },
            logout: {
                sessionStorage.clearSession()
            }
        )

        return RootCoordinator(
            destination: .launch,
            nextDestination: nextDestination,
            actions: actions,
            authDependencies: AuthFlowDependencies(
                kakaoLogin: {
                    try await dependencies.usecases.kakaoAuthUsecase.kakaoLogin()
                },
                googleLogin: {
                    try await dependencies.usecases.googleAuthUsecase.googleLogin()
                },
                appleLogin: { authorization in
                    try await dependencies.usecases.appleAuthUsecase.appleLogin(authorization: authorization)
                },
                checkNickname: { nickname in
                    try await dependencies.usecases.userUsecase.checkNickname(nickname: nickname)
                },
                register: { user in
                    switch user.provider.uppercased() {
                    case "APPLE":
                        try await dependencies.usecases.appleAuthUsecase.appleRegister(user: user)
                    case "GOOGLE":
                        try await dependencies.usecases.googleAuthUsecase.googleRegister(user: user)
                    default:
                        try await dependencies.usecases.kakaoAuthUsecase.kakaoRegister(user: user)
                    }
                }
            )
        )
    }
}
