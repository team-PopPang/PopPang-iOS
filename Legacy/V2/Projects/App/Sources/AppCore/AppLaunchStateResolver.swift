import Coordinator
import Domain
import Foundation

struct AppLaunchStateResolver: Sendable {
    func resolve(snapshot: AppSessionSnapshot) -> RootDestination {
        if snapshot.hasAuthenticatedUser {
            return .main
        }

        return .onboarding
    }

    func resolve(
        snapshot: AppSessionSnapshot,
        userUsecase: UserUsecaseProtocol
    ) async -> AppLaunchResolution {
        guard let userID = snapshot.userID, userID.isEmpty == false else {
            return .destination(.onboarding)
        }

        do {
            let user = try await userUsecase.autoLogin(userUuid: userID)
            if user.nickname == nil {
                return .registrationRequired(user)
            }

            return .authenticated(user)
        } catch {
            return .destination(.onboarding)
        }
    }
}

enum AppLaunchResolution {
    case destination(RootDestination)
    case authenticated(User)
    case registrationRequired(User)
}
