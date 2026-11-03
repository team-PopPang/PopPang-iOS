import AuthFeatureV2
import ComposableArchitecture
import Domain
import SwiftUI

/// 로그인 없이 가입 흐름만 띄워 피그마 화면과 비교한다.
@main
struct AuthFeatureV2DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RegisterFlowFeatureView(
                store: Store(
                    initialState: Self.initialState()
                ) {
                    RegisterFlowFeature()
                } withDependencies: {
                    $0.authFeatureClient = AuthFeatureClient(
                        login: { provider in .pending(provider) },
                        signup: { provider, request in
                            var user = User.demo(provider: provider)
                            user.nickname = request.nickname
                            return user
                        },
                        checkNickname: { _ in false },
                        getRecommendList: {
                            [
                                Recommend(id: 1, recommendName: "디저트"),
                                Recommend(id: 2, recommendName: "캐릭터"),
                                Recommend(id: 3, recommendName: "뷰티"),
                                Recommend(id: 4, recommendName: "패션"),
                                Recommend(id: 5, recommendName: "전시"),
                                Recommend(id: 6, recommendName: "굿즈"),
                                Recommend(id: 7, recommendName: "아이돌"),
                                Recommend(id: 8, recommendName: "라이프"),
                            ]
                        },
                        recommendNickname: {
                            ["설레는수달", "성수팝업러", "용감한판다"].randomElement() ?? "설레는수달"
                        },
                        getPopularKeywords: {
                            ["소금빵", "베이글", "산리오", "포켓몬", "케이크", "레고"]
                        }
                    )
                }
            )
        }
    }
}

private extension AuthFeatureV2DemoApp {
    /// `-demoStep category`면 카테고리 단계(디저트 선택), `-demoStep keyword`면 키워드 단계(두쫀쿠·짱구),
    /// `-demoStep complete`면 가입 완료 화면부터, `-demoStep completeSkipped`면 키워드를 건너뛴 완료 화면부터 띄운다.
    /// 화면 캡처 비교용이다.
    static func initialState() -> RegisterFlowFeature.State {
        var state = RegisterFlowFeature.State(provider: .kakao)
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-demoStep"),
           arguments.indices.contains(index + 1),
           ["category", "keyword", "complete", "completeSkipped"].contains(arguments[index + 1]) {
            let step = arguments[index + 1]
            state.nickname = "성수팝업러"
            state.validationState = .success
            state.currentStep = .category
            state.selectedCategories = [1]
            if step != "category" {
                state.currentStep = .keyword
                state.selectedCategories = [1, 2]
                state.keywords = ["두쫀쿠", "짱구"]
            }
            if step == "complete" || step == "completeSkipped" {
                if step == "completeSkipped" {
                    state.keywords = []
                }
                state.recommendList = [
                    Recommend(id: 1, recommendName: "디저트"),
                    Recommend(id: 2, recommendName: "캐릭터"),
                ]
                var user = User.demo(provider: .kakao)
                user.nickname = state.nickname
                state.signedUpUser = user
                state.currentStep = .complete
            }
        }
        return state
    }
}

private extension User {
    static func demo(provider: Provider) -> User {
        User(
            userUuid: "demo-\(provider.rawValue.lowercased())",
            provider: provider,
            email: nil,
            nickname: "데모유저",
            role: .member,
            isAlerted: false
        )
    }
}
