import ComposableArchitecture
import PopPangRN
import SwiftUI

public struct PopPangRNFeatureView: View {
    @Bindable var store: StoreOf<PopPangRNFeature>

    public init(store: StoreOf<PopPangRNFeature>) {
        self.store = store
    }

    public var body: some View {
        NativepieceView(store.screen.nativepieceScreen(userUuid: store.userUuid))
            .onEvent(PopPangRN.Event.self) { event in
                switch event {
                case .popupRequestSubmitted:
                    store.send(.popupRequestSubmitted)
                }
            }
            // 닫기는 Nativepiece 기본 동작(dismiss·pop) 대신 TCA parent가 화면 상태로 처리한다.
            .onClose {
                store.send(.closeRequested)
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
    }
}

private extension PopPangRNFeature.Screen {
    func nativepieceScreen(userUuid: String) -> PopPangRN.Screen {
        let props = PopPangRN.PopPangScreenProps(userUuid: userUuid)
        switch self {
        case .popupRequest:
            return .popupRequest(props)
        case .popupRequestManagement:
            return .popupRequestManagement(props)
        }
    }
}
