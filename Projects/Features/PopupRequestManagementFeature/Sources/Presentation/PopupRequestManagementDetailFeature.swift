import ComposableArchitecture
import Domain
import Foundation
import PopupSubmissionFormFeature

@Reducer
public struct PopupRequestManagementDetailFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public let adminUuid: String
        public let submissionId: Int
        public var form: PopupSubmissionFormFeature.State
        public var originalDescription: String = ""
        public var status: PopupSubmissionStatus = .pending
        public var isLoading = false
        public var isSubmitting = false
        public var hasLoaded = false
        public var pendingDecision: PopupSubmissionStatus?
        public var errorMessage: String?
        public var resultPopupUuid: String?
        public var isCompleted = false

        public var id: Int { submissionId }

        public init(
            adminUuid: String,
            submissionId: Int
        ) {
            self.adminUuid = adminUuid
            self.submissionId = submissionId
            self.form = .init(mode: .adminReview)
        }
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case approveTapped
        case rejectTapped
        case errorAlertDismissed
        case completionAlertDismissed
        case detailLoaded(PopupSubmissionDetail)
        case detailLoadFailed(String)
        case updateSucceeded(PopupSubmissionAdminUpdateResult)
        case updateFailed(String)
        case form(PopupSubmissionFormFeature.Action)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case pop
        }
    }

    @Dependency(\.popupRequestManagementClient) private var popupRequestManagementClient: PopupRequestManagementClient

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
                state.isLoading = true
                state.errorMessage = nil
                return loadDetail(adminUuid: state.adminUuid, submissionId: state.submissionId)

            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                return loadDetail(adminUuid: state.adminUuid, submissionId: state.submissionId)

            case .approveTapped:
                if let error = PopupSubmissionFormValidator.validateAdmin(state.form) {
                    state.errorMessage = error.localizedDescription
                    return .none
                }

                state.isSubmitting = true
                state.pendingDecision = .approved
                state.errorMessage = nil
                return updateSubmission(
                    adminUuid: state.adminUuid,
                    submissionId: state.submissionId,
                    request: PopupSubmissionFormMapper.makeAdminUpdateRequest(from: state.form, status: .approved)
                )

            case .rejectTapped:
                state.isSubmitting = true
                state.pendingDecision = .rejected
                state.errorMessage = nil
                return updateSubmission(
                    adminUuid: state.adminUuid,
                    submissionId: state.submissionId,
                    request: PopupSubmissionAdminUpdateRequest(status: .rejected)
                )

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .none

            case .completionAlertDismissed:
                state.isCompleted = false
                return .send(.delegate(.pop))

            case .detailLoaded(let detail):
                state.isLoading = false
                state.form = PopupSubmissionFormMapper.makeAdminFormState(from: detail)
                state.originalDescription = detail.description
                state.status = detail.status
                state.errorMessage = nil
                return .none

            case .detailLoadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .updateSucceeded(let result):
                state.isSubmitting = false
                state.status = state.pendingDecision ?? state.status
                state.pendingDecision = nil
                state.resultPopupUuid = result.popupUuid
                state.isCompleted = true
                return .none

            case .updateFailed(let message):
                state.isSubmitting = false
                state.pendingDecision = nil
                state.errorMessage = message
                return .none

            case .form,
                 .delegate:
                return .none
            }
        }
    }
}

private extension PopupRequestManagementDetailFeature {
    func loadDetail(adminUuid: String, submissionId: Int) -> Effect<Action> {
        let popupRequestManagementClient = popupRequestManagementClient

        return .run { [popupRequestManagementClient, adminUuid, submissionId] send in
            do {
                await send(.detailLoaded(
                    try await popupRequestManagementClient.getPopupSubmissionDetail(adminUuid, submissionId)
                ))
            } catch {
                await send(.detailLoadFailed(error.localizedDescription))
            }
        }
    }

    func updateSubmission(
        adminUuid: String,
        submissionId: Int,
        request: PopupSubmissionAdminUpdateRequest
    ) -> Effect<Action> {
        let popupRequestManagementClient = popupRequestManagementClient

        return .run { [popupRequestManagementClient, adminUuid, submissionId, request] send in
            do {
                await send(.updateSucceeded(
                    try await popupRequestManagementClient.updatePopupSubmission(
                        adminUuid,
                        submissionId,
                        request
                    )
                ))
            } catch {
                await send(.updateFailed(error.localizedDescription))
            }
        }
    }
}
