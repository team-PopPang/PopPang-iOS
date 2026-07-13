import ComposableArchitecture
import Core
import Foundation
import AuthFeature
import MainTabFeature

struct AppBootstrap {
    let sessionStorage: LocalSessionStorage
    let localSessionClient: LocalSessionClient
    let mainTabFeatureDependencies: MainTabFeatureDependencies
    let launchStateResolver: AppLaunchStateResolver
    let dependencies: AppDependencyRegistry
    
    /// 실제 앱 실행 환경에서 사용할 의존성 그래프를 생성합니다.
    /// 동일한 `store`와 UseCase 인스턴스를 여러 객체에 전달하여
    /// 앱 내부에서 같은 저장소와 비즈니스 로직 인스턴스를 공유하도록 합니다.
    static func live(
        store: KeyValueStoring = UserDefaultsStore()
    ) -> AppBootstrap {
        // 로컬 세션 저장소
        let sessionStorage = LocalSessionStorage(store: store)
        
        // Repository와 UseCase를 포함한 앱의 실제 의존성 그래프
        let dependencies = AppDependencyRegistry.live()
        
        /// TCA Feature용 LocalSessionClient를 생성
        let localSessionClient = LocalSessionClient.live(
            sessionStorage: sessionStorage,
            userUsecase: dependencies.usecases.userUsecase
        )
        
        // MainTab과 하위 Feature들이 사용할 실제 의존성들을 구성
        let mainTabFeatureDependencies = MainTabFeatureDependencies(
            store: store,
            adminUsecase: dependencies.usecases.adminUsecase,
            popupUsecase: dependencies.usecases.popupUsecase,
            userUsecase: dependencies.usecases.userUsecase
        )
        
        // 푸시 토큰을 로컬에 저장하기 위한 저장소를 생성
        let pushTokenStorage = PushTokenStorage(store: store)
        
        // 알림 처리 객체에도 동일한 세션 저장소와 UserUsecase를 전달
        AppNotificationManager.shared.configure(
            sessionStorage: sessionStorage,
            pushTokenStorage: pushTokenStorage,
            userUsecase: dependencies.usecases.userUsecase
        )

        return AppBootstrap(
            sessionStorage: sessionStorage,
            localSessionClient: localSessionClient,
            mainTabFeatureDependencies: mainTabFeatureDependencies,
            launchStateResolver: AppLaunchStateResolver(),
            dependencies: dependencies
        )
    }

    // MARK: - 의존성을 만드는 시점과 TCA Store에 연결하는 시점이 다르기 때문
    /// 앱의 최상위 TCA Store를 생성합니다.
    /// `AppBootstrap.live()`에서 미리 조립한 실제 Client와 UseCase 기반 구현을
    /// `withDependencies`를 통해 AppFeature와 모든 하위 Reducer에 전달합니다.
    func makeAppStore() -> StoreOf<AppFeature> {
        Store(initialState: AppFeature.State()) {
            AppFeature(
                sessionStorage: sessionStorage,
                launchStateResolver: launchStateResolver
            )
        } withDependencies: {
            $0.localSessionClient = localSessionClient
            mainTabFeatureDependencies.configure(&$0)
            $0.authFeatureClient = .live(
                kakaoAuthUsecase: dependencies.usecases.kakaoAuthUsecase,
                googleAuthUsecase: dependencies.usecases.googleAuthUsecase,
                appleAuthUsecase: dependencies.usecases.appleAuthUsecase,
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
