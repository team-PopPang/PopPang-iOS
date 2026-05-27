import Data
import Domain
import PopupDetailFeature
import SwiftUI

@main
struct PopupDetailFeatureDemoApp: App {
    init() {
        let popupRepository = PopupRepositoryImpl()
        let popupUsecase = PopupUsecaseImpl(popupRepository: popupRepository)
        let adminRepository = AdminRepositoryImpl()
        let adminUsecase = AdminUsecaseImpl(adminRepository: adminRepository)
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(adminUsecase, for: AdminUsecaseProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            PopupDetailFeatureView()
        }
    }
}
