import Compound
import Domain
import Foundation

public enum PopupRequestManagementStatus: String, CaseIterable, Hashable, Sendable {
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .pending:
            "검토 대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }

    init(status: PopupSubmissionStatus) {
        switch status {
        case .pending:
            self = .pending
        case .approved:
            self = .approved
        case .rejected:
            self = .rejected
        }
    }
}

public enum PopupRequestManagementFilter: CaseIterable, Hashable, Sendable {
    case all
    case pending
    case approved
    case rejected

    var title: String {
        switch self {
        case .all:
            "전체"
        case .pending:
            "대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }

    var status: PopupRequestManagementStatus? {
        switch self {
        case .all:
            nil
        case .pending:
            .pending
        case .approved:
            .approved
        case .rejected:
            .rejected
        }
    }
}

public struct PopupRequestManagementItem: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let popupName: String
    public let region: String
    public let address: String
    public let periodText: String
    public let description: String
    public let submittedAtText: String
    public let submitterNickname: String
    public let status: PopupRequestManagementStatus

    public init(
        id: String,
        popupName: String,
        region: String,
        address: String,
        periodText: String = "",
        description: String = "",
        submittedAtText: String,
        submitterNickname: String,
        status: PopupRequestManagementStatus
    ) {
        self.id = id
        self.popupName = popupName
        self.region = region
        self.address = address
        self.periodText = periodText
        self.description = description
        self.submittedAtText = submittedAtText
        self.submitterNickname = submitterNickname
        self.status = status
    }
}

@Compound
final class PopupRequestManagementFeatureCompound {
    enum Action: Sendable {
        case onAppear
        case refresh
        case filterSelected(PopupRequestManagementFilter)
    }

    enum Reaction: Sendable {
        case setLoading(Bool)
        case setItems([PopupRequestManagementItem])
        case setFilter(PopupRequestManagementFilter)
        case setErrorMessage(String?)
    }

    struct State: Equatable, Sendable {
        var items: [PopupRequestManagementItem] = []
        var selectedFilter: PopupRequestManagementFilter = .all
        var isLoading = false
        var errorMessage: String?
    }

    var state = State()

    @Dependency private var adminUsecase: AdminUsecaseProtocol

    init(items: [PopupRequestManagementItem] = []) {
        state.items = items
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return loadSubmissions()
        case .refresh:
            return loadSubmissions()
        case .filterSelected(let filter):
            return .just(.setFilter(filter))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setItems(let items):
            newState.items = items
        case .setFilter(let filter):
            newState.selectedFilter = filter
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }
}

@Compound
final class PopupRequestManagementDetailFeatureCompound {
    enum Action: Sendable {
        case onAppear
        case refresh
    }

    enum Reaction: Sendable {
        case setLoading(Bool)
        case setItem(PopupRequestManagementItem?)
        case setErrorMessage(String?)
    }

    struct State: Equatable, Sendable {
        let submissionId: String
        var item: PopupRequestManagementItem?
        var isLoading = false
        var errorMessage: String?
    }

    var state: State

    @Dependency private var adminUsecase: AdminUsecaseProtocol

    init(submissionId: String) {
        state = State(submissionId: submissionId)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return loadSubmission()
        case .refresh:
            return loadSubmission()
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setItem(let item):
            newState.item = item
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }
}

extension PopupRequestManagementFeatureCompound.State {
    var filteredItems: [PopupRequestManagementItem] {
        guard let status = selectedFilter.status else { return items }
        return items.filter { $0.status == status }
    }

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
    }

    var approvedCount: Int {
        items.filter { $0.status == .approved }.count
    }

    var rejectedCount: Int {
        items.filter { $0.status == .rejected }.count
    }
}

private extension PopupRequestManagementDetailFeatureCompound {
    func loadSubmission() -> AsyncStream<Reaction> {
        guard state.isLoading == false else { return emptyReactionStream() }

        let adminUsecase = adminUsecase
        let submissionId = state.submissionId

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [adminUsecase, submissionId] send in
                do {
                    let submissions = try await adminUsecase.getPopupSubmissionList()
                    let items = submissions.map { $0.toManagementItem() }

                    guard let item = items.first(where: { $0.id == submissionId }) else {
                        await send(.setItem(nil))
                        await send(.setErrorMessage("해당 팝업 제보를 찾을 수 없습니다."))
                        await send(.setLoading(false))
                        return
                    }

                    await send(.setItem(item))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private extension PopupRequestManagementFeatureCompound {
    func loadSubmissions() -> AsyncStream<Reaction> {
        guard state.isLoading == false else { return emptyReactionStream() }

        let adminUsecase = adminUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [adminUsecase] send in
                do {
                    let submissions = try await adminUsecase.getPopupSubmissionList()
                    await send(.setItems(submissions.map { $0.toManagementItem() }))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private extension PopupSubmission {
    func toManagementItem() -> PopupRequestManagementItem {
        PopupRequestManagementItem(
            id: String(id),
            popupName: name,
            region: address.regionText,
            address: address,
            periodText: "\(startDate) - \(endDate)",
            description: description,
            submittedAtText: createdAt.popupSubmissionDateText,
            submitterNickname: "제보자",
            status: PopupRequestManagementStatus(status: status)
        )
    }
}

private extension String {
    var popupSubmissionDateText: String {
        split(separator: "T").first.map(String.init) ?? self
    }

    var regionText: String {
        split(separator: " ").first.map(String.init) ?? "-"
    }
}
