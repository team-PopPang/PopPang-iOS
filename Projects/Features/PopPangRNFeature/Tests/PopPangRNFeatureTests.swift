import ComposableArchitecture
import Testing
@testable import PopPangRNFeature

@MainActor
struct PopPangRNFeatureTests {
    @Test("팝업 제보에서 제출을 마치면 화면을 닫는다")
    func popupRequestSubmittedDismisses() async {
        let store = makeStore(screen: .popupRequest)

        await store.send(.popupRequestSubmitted)
        await store.receive(.delegate(.dismiss))
    }

    @Test("팝업 제보에서 뒤로가기를 누르면 화면을 닫는다")
    func popupRequestCloseDismisses() async {
        let store = makeStore(screen: .popupRequest)

        await store.send(.closeRequested)
        await store.receive(.delegate(.dismiss))
    }

    @Test("제보 관리에서 뒤로가기를 누르면 이전 화면으로 돌아간다")
    func popupRequestManagementClosePops() async {
        let store = makeStore(screen: .popupRequestManagement)

        await store.send(.closeRequested)
        await store.receive(.delegate(.pop))
    }

    @Test("제보 관리는 제출 완료 이벤트로 화면을 바꾸지 않는다")
    func popupRequestManagementIgnoresSubmitted() async {
        let store = makeStore(screen: .popupRequestManagement)

        await store.send(.popupRequestSubmitted)
    }

    private func makeStore(screen: PopPangRNFeature.Screen) -> TestStoreOf<PopPangRNFeature> {
        TestStore(initialState: PopPangRNFeature.State(screen: screen, userUuid: "user-1")) {
            PopPangRNFeature()
        }
    }
}
