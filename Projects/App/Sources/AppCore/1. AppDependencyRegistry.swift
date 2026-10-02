import Data
import Domain
import Foundation

// repository
struct AppRepositoryRegistry {
    let adminRepository: AdminRepositoryProtocol
    let appleAuthRepository: AppleAuthRepositoryProtocol
    let googleAuthRepository: GoogleAuthRepositoryProtocol
    let kakaoAuthRepository: KakaoAuthRepositoryProtocol
    let popupRepository: PopupRepositoryProtocol
    let serverHealthRepository: ServerHealthRepositoryProtocol
    let userRepository: UserRepositoryProtocol

    static func live() -> AppRepositoryRegistry {
        AppRepositoryRegistry(
            adminRepository: AdminRepositoryImpl(),
            appleAuthRepository: AppleAuthRepositoryImpl(),
            googleAuthRepository: GoogleAuthRepositoryImpl(),
            kakaoAuthRepository: KakaoAuthRepositoryImpl(),
            popupRepository: PopupRepositoryImpl(),
            serverHealthRepository: ServerHealthRepositoryImpl(),
            userRepository: UserRepositoryImpl()
        )
    }
}

// usecase
struct AppUsecaseRegistry {
    let adminUsecase: AdminUsecaseProtocol
    let appleAuthUsecase: AppleAuthUsecaseProtocol
    let googleAuthUsecase: GoogleAuthUsecaseProtocol
    let kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    let popupUsecase: PopupUsecaseProtocol
    let serverHealthUsecase: ServerHealthUsecaseProtocol
    let userUsecase: UserUsecaseProtocol

    init(repositories: AppRepositoryRegistry) {
        self.adminUsecase = AdminUsecaseImpl(adminRepository: repositories.adminRepository)
        self.appleAuthUsecase = AppleAuthUsecaseImpl(appleAuthRepository: repositories.appleAuthRepository)
        self.googleAuthUsecase = GoogleAuthUsecaseImpl(googleAuthRepository: repositories.googleAuthRepository)
        self.kakaoAuthUsecase = KakaoAuthUsecaseImpl(kakaoAuthRepository: repositories.kakaoAuthRepository)
        self.popupUsecase = PopupUsecaseImpl(popupRepository: repositories.popupRepository)
        self.serverHealthUsecase = ServerHealthUsecaseImpl(serverHealthRepository: repositories.serverHealthRepository)
        self.userUsecase = UserUsecaseImpl(userRepository: repositories.userRepository)
    }
}

// usecase dependency
struct AppDependencyRegistry {
    let repositories: AppRepositoryRegistry
    let usecases: AppUsecaseRegistry

    init(repositories: AppRepositoryRegistry) {
        self.repositories = repositories
        self.usecases = AppUsecaseRegistry(repositories: repositories)
    }

    static func live() -> AppDependencyRegistry {
        AppDependencyRegistry(repositories: .live())
    }
}
