import ComposableArchitecture
import Testing
@testable import FlutterPopupManagementFeature

@MainActor
struct FlutterPopupManagementFeatureTests {
    @Test("초기 상태에서 Flutter 뷰는 아직 연결되지 않는다")
    func initialStateStartsDisconnected() async {
        let store = TestStore(initialState: FlutterPopupManagementFeature.State()) {
            FlutterPopupManagementFeature()
        }

        #expect(store.state.isFlutterViewAttached == false)
        #expect(store.state.bridgeStatusText == "Flutter view is not connected yet.")

        await store.send(.onAppear)
    }
}
