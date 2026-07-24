import ComposableArchitecture
import Data
import Domain
import HomeFeatureV2
import SwiftUI

@main
struct HomeFeatureV2DemoApp: App {
    
    private let demoUserUuid = Bundle.main.object(
        forInfoDictionaryKey: "HOME_DEMO_USER_UUID"
    ) as? String ?? ""
    private let homePopupClient = HomePopupClient.live(
        popupUsecase: PopupUsecaseImpl(
            popupRepository: PopupRepositoryImpl()
        )
    )
    
    init() {
        print("테스트: \(demoUserUuid)")
    }
    
    var body: some Scene {
        WindowGroup {
            HomeFeatureView(
                store: Store(
                    initialState: HomeFeature.State(
                        user: User(
                            userUuid: demoUserUuid,
                            uid: "preview-uid",
                            provider: "preview",
                            email: nil,
                            nickname: "홍길동",
                            role: "ADMIN",
                            isAlerted: false,
                            fcmToken: nil,
                            alertKeywordList: nil,
                            recommendList: nil
                        )
                    )
                ) {
                    HomeFeature()
                }
                withDependencies: {
                    $0.homePopupClient = homePopupClient
                    // $0.homePopupClient = .previewValue
                }
            )
        }
    }
}






//                    $0.homePopupClient.getPersonalRandomPopupList = { _ in
//                        Array(repeating: .popupMock, count: 20)
//                    }

//#Preview {
//    HomeFeatureView(
//        store: Store(
//            initialState: HomeFeature.State(popups: [
//                .popupMock,
//                .popupMock,
//                .popupMock,
//                .popupMock,
//                .popupMock,
//                .popupMock
//            ])
//        ) {
//            HomeFeature()
//        }
//    )
//}
