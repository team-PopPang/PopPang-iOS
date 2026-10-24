import Core
import Data
import Domain
import Foundation

// repository
struct AppRepositoryRegistry {
    let adminRepository: AdminRepositoryProtocol
    let authRepository: AuthRepositoryProtocol
    let popupRepository: PopupRepositoryProtocol
    let serverHealthRepository: ServerHealthRepositoryProtocol
    let userRepository: UserRepositoryProtocol

    static func live(tokenStorage: AuthTokenStorage) -> AppRepositoryRegistry {
        AppRepositoryRegistry(
            adminRepository: AdminRepositoryImpl(),
            authRepository: AuthRepositoryImpl(tokenStorage: tokenStorage),
            popupRepository: PopupRepositoryImpl(),
            serverHealthRepository: ServerHealthRepositoryImpl(),
            userRepository: UserRepositoryImpl(tokenStorage: tokenStorage)
        )
    }
}

// usecase
struct AppUsecaseRegistry {
    let adminUsecase: AdminUsecaseProtocol
    let authUsecase: AuthUsecaseProtocol
    let popupUsecase: PopupUsecaseProtocol
    let serverHealthUsecase: ServerHealthUsecaseProtocol
    let userUsecase: UserUsecaseProtocol

    init(repositories: AppRepositoryRegistry) {
        self.adminUsecase = AdminUsecaseImpl(adminRepository: repositories.adminRepository)
        self.authUsecase = AuthUsecaseImpl(authRepository: repositories.authRepository)
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

    static func live(tokenStorage: AuthTokenStorage) -> AppDependencyRegistry {
        AppDependencyRegistry(repositories: .live(tokenStorage: tokenStorage))
    }
}
