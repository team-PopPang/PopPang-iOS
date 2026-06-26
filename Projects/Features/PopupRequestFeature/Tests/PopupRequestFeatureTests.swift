import ComposableArchitecture
import Domain
import PopupSubmissionFormFeature
import Testing
@testable import PopupRequestFeature

@MainActor
struct PopupRequestFeatureTests {
    @Test("팝업 제보 화면이 최초 진입 시 추천 카테고리를 로드한다")
    func loadsRecommendListOnAppear() async {
        let expected = [Recommend(id: 1, recommendName: "패션")]

        let store = TestStore(
            initialState: PopupRequestFeature.State(userUuid: "user-1")
        ) {
            PopupRequestFeature()
        } withDependencies: {
            $0.popupRequestClient.getRecommendList = { expected }
        }

        await store.send(.onAppear) {
            $0.hasLoaded = true
        }

        await store.receive(.recommendListLoaded(expected)) {
            $0.form.recommendList = expected
            $0.errorMessage = nil
        }
    }

    @Test("팝업 제보가 유효한 폼이면 제출 요청을 보낸다")
    func submitsValidRequest() async throws {
        var state = PopupRequestFeature.State(userUuid: "user-1")
        state.form.name = "성수 팝업"
        state.form.roadAddress = "서울 성동구 성수이로 00"
        state.form.region = "서울"
        state.form.descriptionText = "브랜드 팝업"
        state.form.selectedRecommendIds = [3]
        state.form.imageItems = [PopupSubmissionImageItem(imageUrl: "https://cdn.example.com/a.jpg")]

        let store = TestStore(initialState: state) {
            PopupRequestFeature()
        } withDependencies: {
            $0.popupRequestClient.createPopupSubmission = { request in
                #expect(request.userUuid == "user-1")
                #expect(request.name == "성수 팝업")
                #expect(request.recommendIdList == [3])
                #expect(request.imageList.map(\.imageUrl) == ["https://cdn.example.com/a.jpg"])
            }
        }

        await store.send(.submitButtonTapped) {
            $0.isSubmitting = true
            $0.errorMessage = nil
        }

        await store.receive(.submissionSucceeded) {
            $0.isSubmitting = false
            $0.isSubmitted = true
        }
    }
}
