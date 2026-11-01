import ComposableArchitecture
import DSKit
import Testing
@testable import OnboardingFeatureV2

@MainActor
struct OnboardingFeatureV2Tests {
    @Test("다음을 누르면 다음 화면으로 간다")
    func nextMovesToNextStep() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.nextTapped) {
            $0.currentStep = .map
        }
        await store.send(.nextTapped) {
            $0.currentStep = .favorite
        }
    }

    @Test("마지막 화면에서 다음을 누르면 로그인을 요청한다")
    func nextOnLastStepRequestsAuth() async {
        var state = OnboardingFeature.State()
        state.currentStep = .favorite
        let store = TestStore(initialState: state) {
            OnboardingFeature()
        }

        await store.send(.nextTapped)
        await store.receive(.delegate(.authRequested))
    }

    @Test("건너뛰기를 누르면 로그인을 요청한다")
    func skipRequestsAuth() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.skipTapped)
        await store.receive(.delegate(.authRequested))
    }

    @Test("화면마다 쓰는 그림 카드와 아이콘이 DSKit 에셋에 있다", arguments: OnboardingStep.allCases)
    func stepAssetsExist(step: OnboardingStep) {
        #expect(DSKitResource.uiImage(named: step.card) != nil)
        #expect(DSKitResource.uiImage(named: step.icon) != nil)
    }

    @Test("다음 버튼 화살표가 DSKit 에셋에 있다")
    func arrowAssetExists() {
        #expect(DSKitResource.uiImage(named: "OnboardingV2Arrow") != nil)
    }

    @Test("옆으로 넘기면 그 화면으로 바뀐다")
    func swipeChangesStep() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }

        await store.send(.stepChanged(.favorite)) {
            $0.currentStep = .favorite
        }
    }
}
