import ComposableArchitecture
import Domain
import HomeFeatureV2
import SwiftUI

@main
struct HomeFeatureV2DemoApp: App {
    var body: some Scene {
        WindowGroup {
//            HomeFeatureView(
//                store: Store(
//                    initialState: HomeFeature.State(
//                        user: User(
//                            userUuid: "demo-user",
//                            uid: "demo-uid",
//                            provider: "preview",
//                            email: nil,
//                            nickname: "팝팡",
//                            role: "ADMIN",
//                            isAlerted: false,
//                            fcmToken: nil,
//                            alertKeywordList: nil,
//                            recommendList: nil
//                        )
//                    )
//                ) {
//                    HomeFeature()
//                } withDependencies: {
//                    $0.homePopupClient = .previewValue
//                }
//            )
            
            // HomeFeatureView()
//            HomeFeatureView(
//                store: Store(
//                    initialState: HomeFeature.State(popups: [
//                        .popupMock,
//                        .popupMock,
//                        .popupMock,
//                        .popupMock,
//                        .popupMock,
//                        .popupMock
//                    ])
//                ) {
//                    HomeFeature()
//                }
//            )
            
            HomeFeatureView(
                store: Store(
                    initialState: HomeFeature.State(
                        user: User(
                            userUuid: "preview-user",
                            uid: "preview-uid",
                            provider: "preview",
                            email: nil,
                            nickname: "홍길동",
                            role: "USER",
                            isAlerted: false,
                            fcmToken: nil,
                            alertKeywordList: nil,
                            recommendList: nil
                        ), bestPopups: [
                            .popupMock,
                            .popupMock,
                            .popupMock,
                            .popupMock,
                            .popupMock,
                            .popupMock
                        ]
                    )
                ) {
                    HomeFeature()
                }
            )
        }
    }
}

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
