import Data
import Domain
import HomeFeature
import SwiftUI

@main
struct HomeFeatureDemoApp: App {
    @State private var coordinator = HomeFeatureCoordinator()

    init() {
        let popupRepository = PopupRepositoryImpl()
        let popupUsecase = PopupUsecaseImpl(popupRepository: popupRepository)
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            HomeFeatureView()
                .environment(coordinator)
        }
    }
}
