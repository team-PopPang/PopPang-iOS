import Data
import Domain
import Foundation

struct AppRepositoryRegistry {
    let adminRepository: AdminRepositoryProtocol
    let appleAuthRepository: AppleAuthRepositoryProtocol
    let googleAuthRepository: GoogleAuthRepositoryProtocol
    let kakaoAuthRepository: KakaoAuthRepositoryProtocol
    let popupRepository: PopupRepositoryProtocol
    let popupSubmissionRepository: PopupSubmissionRepositoryProtocol
    let userRepository: UserRepositoryProtocol

    static func live() -> AppRepositoryRegistry {
        AppRepositoryRegistry(
            adminRepository: AdminRepositoryImpl(),
            appleAuthRepository: AppleAuthRepositoryImpl(),
            googleAuthRepository: GoogleAuthRepositoryImpl(),
            kakaoAuthRepository: KakaoAuthRepositoryImpl(),
            popupRepository: PopupRepositoryImpl(),
            popupSubmissionRepository: PopupSubmissionRepositoryImpl(),
            userRepository: UserRepositoryImpl()
        )
    }
}

struct AppUsecaseRegistry {
    let adminUsecase: AdminUsecaseProtocol
    let appleAuthUsecase: AppleAuthUsecaseProtocol
    let googleAuthUsecase: GoogleAuthUsecaseProtocol
    let kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    let popupUsecase: PopupUsecaseProtocol
    let popupSubmissionUsecase: PopupSubmissionUsecaseProtocol
    let userUsecase: UserUsecaseProtocol

    init(repositories: AppRepositoryRegistry) {
        self.adminUsecase = AdminUsecaseImpl(adminRepository: repositories.adminRepository)
        self.appleAuthUsecase = AppleAuthUsecaseImpl(appleAuthRepository: repositories.appleAuthRepository)
        self.googleAuthUsecase = GoogleAuthUsecaseImpl(googleAuthRepository: repositories.googleAuthRepository)
        self.kakaoAuthUsecase = KakaoAuthUsecaseImpl(kakaoAuthRepository: repositories.kakaoAuthRepository)
        self.popupUsecase = PopupUsecaseImpl(popupRepository: repositories.popupRepository)
        self.popupSubmissionUsecase = PopupSubmissionUsecaseImpl(repository: repositories.popupSubmissionRepository)
        self.userUsecase = UserUsecaseImpl(userRepository: repositories.userRepository)
    }
}

struct AppDependencyRegistry {
    let repositories: AppRepositoryRegistry
    let usecases: AppUsecaseRegistry

    init(repositories: AppRepositoryRegistry) {
        self.repositories = repositories
        self.usecases = AppUsecaseRegistry(repositories: repositories)
        registerUsecases()
    }

    static func live() -> AppDependencyRegistry {
        AppDependencyRegistry(repositories: .live())
    }

    private func registerUsecases() {
        DIContainer.shared.register(usecases.adminUsecase, for: AdminUsecaseProtocol.self)
        DIContainer.shared.register(usecases.appleAuthUsecase, for: AppleAuthUsecaseProtocol.self)
        DIContainer.shared.register(usecases.googleAuthUsecase, for: GoogleAuthUsecaseProtocol.self)
        DIContainer.shared.register(usecases.kakaoAuthUsecase, for: KakaoAuthUsecaseProtocol.self)
        DIContainer.shared.register(usecases.popupUsecase, for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(usecases.popupSubmissionUsecase, for: PopupSubmissionUsecaseProtocol.self)
        DIContainer.shared.register(usecases.userUsecase, for: UserUsecaseProtocol.self)
    }
}
