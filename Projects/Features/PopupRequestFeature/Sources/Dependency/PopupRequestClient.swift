import ComposableArchitecture
import Domain
import Foundation

public struct PopupRequestClient: Sendable {
    var getRecommendList: @Sendable () async throws -> [Recommend]
    var createPopupSubmission: @Sendable (PopupSubmissionCreateRequest) async throws -> Void
}

extension PopupRequestClient {
    public static func live(
        popupSubmissionUsecase: PopupSubmissionUsecaseProtocol,
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        let popupSubmissionUsecaseBox = PopupSubmissionUsecaseBox(popupSubmissionUsecase)
        let userUsecaseBox = UserUsecaseBox(userUsecase)

        return Self(
            getRecommendList: {
                try await userUsecaseBox.usecase.getRecommandList()
            },
            createPopupSubmission: { request in
                try await popupSubmissionUsecaseBox.usecase.createPopupSubmission(request)
            }
        )
    }
}

extension PopupRequestClient: DependencyKey {
    public static let liveValue = PopupRequestClient(
        getRecommendList: { [] },
        createPopupSubmission: { _ in }
    )

#if DEBUG
    public static let previewValue = PopupRequestClient(
        getRecommendList: {
            [
                Recommend(id: 1, recommendName: "패션"),
                Recommend(id: 2, recommendName: "디저트"),
                Recommend(id: 3, recommendName: "라이프스타일"),
            ]
        },
        createPopupSubmission: { _ in }
    )
#endif
}

extension PopupRequestClient: TestDependencyKey {
    public static let testValue = PopupRequestClient(
        getRecommendList: { [] },
        createPopupSubmission: { _ in }
    )
}

extension DependencyValues {
    public var popupRequestClient: PopupRequestClient {
        get { self[PopupRequestClient.self] }
        set { self[PopupRequestClient.self] = newValue }
    }
}

private final class PopupSubmissionUsecaseBox: @unchecked Sendable {
    let usecase: PopupSubmissionUsecaseProtocol

    init(_ usecase: PopupSubmissionUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class UserUsecaseBox: @unchecked Sendable {
    let usecase: UserUsecaseProtocol

    init(_ usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
}
