import ComposableArchitecture
import Domain
import Foundation
import PopupSubmissionFormFeature

@Reducer
public struct PopupRequestFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public let userUuid: String
        public var form: PopupSubmissionFormFeature.State
        public var isSubmitting = false
        public var hasLoaded = false
        public var errorMessage: String?
        public var isSubmitted = false

        public var id: String { "popup-request-\(userUuid)" }

        public init(userUuid: String) {
            self.userUuid = userUuid
            self.form = .init(mode: .userCreate, imageItems: [PopupSubmissionImageItem()])
        }
    }

    public enum Action: Equatable {
        case onAppear
        case dismissTapped
        case submitButtonTapped
        case errorAlertDismissed
        case successAlertDismissed
        case recommendListLoaded([Recommend])
        case recommendListFailed(String)
        case submissionSucceeded
        case submissionFailed(String)
        case form(PopupSubmissionFormFeature.Action)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    @Dependency(\.popupRequestClient) private var popupRequestClient: PopupRequestClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.form, action: \.form) {
            PopupSubmissionFormFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoaded == false else { return .none }
                state.hasLoaded = true
                return loadRecommendList()

            case .dismissTapped:
                return .send(.delegate(.dismiss))

            case .submitButtonTapped:
                if let error = PopupSubmissionFormValidator.validateUser(state.form) {
                    state.errorMessage = error.localizedDescription
                    return .none
                }

                state.isSubmitting = true
                state.errorMessage = nil
                return submit(
                    request: PopupSubmissionFormMapper.makeCreateRequest(
                        from: state.form,
                        userUuid: state.userUuid
                    )
                )

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .none

            case .successAlertDismissed:
                state.isSubmitted = false
                return .send(.delegate(.dismiss))

            case .recommendListLoaded(let recommendList):
                state.form.recommendList = recommendList
                state.errorMessage = nil
                return .none

            case .recommendListFailed(let message):
                state.errorMessage = message
                return .none

            case .submissionSucceeded:
                state.isSubmitting = false
                state.isSubmitted = true
                return .none

            case .submissionFailed(let message):
                state.isSubmitting = false
                state.errorMessage = message
                return .none

            case .form,
                 .delegate:
                return .none
            }
        }
    }
}

private extension PopupRequestFeature {
    func loadRecommendList() -> Effect<Action> {
        let popupRequestClient = popupRequestClient

        return .run { [popupRequestClient] send in
            do {
                await send(.recommendListLoaded(try await popupRequestClient.getRecommendList()))
            } catch {
                await send(.recommendListFailed(error.localizedDescription))
            }
        }
    }

    func submit(request: PopupSubmissionCreateRequest) -> Effect<Action> {
        let popupRequestClient = popupRequestClient

        return .run { [popupRequestClient, request] send in
            do {
                try await popupRequestClient.createPopupSubmission(request)
                await send(.submissionSucceeded)
            } catch {
                await send(.submissionFailed(error.localizedDescription))
            }
        }
    }
}
