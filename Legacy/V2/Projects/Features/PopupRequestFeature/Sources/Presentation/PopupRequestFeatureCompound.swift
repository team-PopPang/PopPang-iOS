import Compound
import Core
import Domain
import Foundation

@Compound
final class PopupRequestFeatureCompound {
    enum Action {
        case onAppear
        case textChanged(PopupRequestTextField, String)
        case startDateChanged(Date)
        case endDateChanged(Date)
        case categoryToggled(Int)
        case imagesLoaded([PopupRequestSelectedImage])
        case imageRemoved(UUID)
        case imageLoadingFailed(String)
        case submit
        case dismissError
        case dismissSuccess
    }

    enum Reaction {
        case setText(PopupRequestTextField, String)
        case setStartDate(Date)
        case setEndDate(Date)
        case setRecommendList([Recommend])
        case setSelectedRecommendIds([Int])
        case setImages([PopupRequestSelectedImage])
        case removeImage(UUID)
        case setSubmitting(Bool)
        case setErrorMessage(String?)
        case setSubmitted(Bool)
    }

    struct State: Equatable {
        var userUuid = ""
        var name = ""
        var startDate = Date()
        var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        var roadAddress = ""
        var region = ""
        var instaPostUrl = ""
        var captionSummary = ""
        var address = ""
        var openTime = ""
        var closeTime = ""
        var latitude = ""
        var longitude = ""
        var recommendList: [Recommend] = []
        var selectedRecommendIds: [Int] = []
        var images: [PopupRequestSelectedImage] = []
        var isSubmitting = false
        var errorMessage: String?
        var isSubmitted = false
    }

    var state = State()

    @Dependency private var adminUsecase: AdminUsecaseProtocol
    @Dependency private var userUsecase: UserUsecaseProtocol

    init(userUuid: String = "demo-user") {
        state.userUuid = userUuid
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return loadRecommendList()

        case let .textChanged(field, text):
            return .just(.setText(field, text))

        case .startDateChanged(let date):
            return .just(.setStartDate(date))

        case .endDateChanged(let date):
            return .just(.setEndDate(date))

        case .categoryToggled(let id):
            var selectedRecommendIds = state.selectedRecommendIds
            if let index = selectedRecommendIds.firstIndex(of: id) {
                selectedRecommendIds.remove(at: index)
            } else {
                selectedRecommendIds.append(id)
            }
            return .just(.setSelectedRecommendIds(selectedRecommendIds))

        case .imagesLoaded(let images):
            return .just(.setImages(images))

        case .imageRemoved(let id):
            return .just(.removeImage(id))

        case .imageLoadingFailed(let message):
            return .just(.setErrorMessage(message))

        case .submit:
            guard state.isSubmitting == false else { return emptyReactionStream() }

            switch makeSubmissionPayload(from: state) {
            case .success(let payload):
                return submit(payload: payload)
            case .failure(let error):
                return .just(.setErrorMessage(error.localizedDescription))
            }

        case .dismissError:
            return .just(.setErrorMessage(nil))

        case .dismissSuccess:
            return .just(.setSubmitted(false))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case let .setText(field, text):
            newState.update(field: field, text: text)
        case .setStartDate(let date):
            newState.startDate = date
            if newState.endDate < date {
                newState.endDate = date
            }
        case .setEndDate(let date):
            newState.endDate = date
        case .setRecommendList(let recommendList):
            newState.recommendList = recommendList
        case .setSelectedRecommendIds(let selectedRecommendIds):
            newState.selectedRecommendIds = selectedRecommendIds
        case .setImages(let images):
            newState.images = images
        case .removeImage(let id):
            newState.images.removeAll { $0.id == id }
        case .setSubmitting(let isSubmitting):
            newState.isSubmitting = isSubmitting
        case .setErrorMessage(let message):
            newState.errorMessage = message
        case .setSubmitted(let isSubmitted):
            newState.isSubmitted = isSubmitted
        }

        return newState
    }
}

enum PopupRequestTextField: Hashable {
    case name
    case roadAddress
    case region
    case instaPostUrl
    case captionSummary
    case address
    case openTime
    case closeTime
    case latitude
    case longitude
}

struct PopupRequestSelectedImage: Identifiable, Equatable {
    let id: UUID
    let data: Data
    let fileName: String
    let mimeType: String

    init(
        id: UUID = UUID(),
        data: Data,
        fileName: String,
        mimeType: String
    ) {
        self.id = id
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

private struct PopupRequestSubmissionPayload {
    let request: PopupSubmissionCreateRequest
}

private struct PopupRequestValidationError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

extension PopupRequestFeatureCompound.State {
    var isSubmitEnabled: Bool {
        trimmed(.name).isEmpty == false &&
            trimmed(.roadAddress).isEmpty == false &&
            trimmed(.region).isEmpty == false &&
            trimmed(.captionSummary).isEmpty == false &&
            selectedRecommendIds.isEmpty == false &&
            images.isEmpty == false &&
            isSubmitting == false
    }

    func text(for field: PopupRequestTextField) -> String {
        switch field {
        case .name:
            name
        case .roadAddress:
            roadAddress
        case .region:
            region
        case .instaPostUrl:
            instaPostUrl
        case .captionSummary:
            captionSummary
        case .address:
            address
        case .openTime:
            openTime
        case .closeTime:
            closeTime
        case .latitude:
            latitude
        case .longitude:
            longitude
        }
    }

    func trimmed(_ field: PopupRequestTextField) -> String {
        text(for: field).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func update(field: PopupRequestTextField, text: String) {
        switch field {
        case .name:
            name = text
        case .roadAddress:
            roadAddress = text
        case .region:
            region = text
        case .instaPostUrl:
            instaPostUrl = text
        case .captionSummary:
            captionSummary = text
        case .address:
            address = text
        case .openTime:
            openTime = text
        case .closeTime:
            closeTime = text
        case .latitude:
            latitude = text
        case .longitude:
            longitude = text
        }
    }
}

private extension PopupRequestFeatureCompound {
    func loadRecommendList() -> AsyncStream<Reaction> {
        guard state.recommendList.isEmpty else { return emptyReactionStream() }

        let userUsecase = userUsecase

        return .run { send in
            do {
                let recommendList = try await userUsecase.getRecommandList()
                await send(.setRecommendList(recommendList))
            } catch {
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
    }

    func submit(payload: PopupRequestSubmissionPayload) -> AsyncStream<Reaction> {
        let adminUsecase = adminUsecase

        return .concat(
            .just(.setSubmitting(true)),
            .just(.setErrorMessage(nil)),
            .run { [adminUsecase, payload] send in
                do {
                    try await adminUsecase.createPopupSubmission(payload.request)
                    await send(.setSubmitted(true))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setSubmitting(false))
            }
        )
    }

    func makeSubmissionPayload(
        from state: State
    ) -> Result<PopupRequestSubmissionPayload, PopupRequestValidationError> {
        let name = state.trimmed(.name)
        let roadAddress = state.trimmed(.roadAddress)
        let region = state.trimmed(.region)
        let instaPostUrl = state.trimmed(.instaPostUrl)
        let captionSummary = state.trimmed(.captionSummary)
        let submitterUserUuid = state.userUuid.trimmingCharacters(in: .whitespacesAndNewlines)

        guard name.isEmpty == false else { return .failure(.init(message: "팝업명을 입력해 주세요.")) }
        guard roadAddress.isEmpty == false else { return .failure(.init(message: "도로명 주소를 입력해 주세요.")) }
        guard region.isEmpty == false else { return .failure(.init(message: "지역을 입력해 주세요.")) }
        guard instaPostUrl.isEmpty || isValidWebURL(instaPostUrl) else {
            return .failure(.init(message: "인스타그램 URL을 올바르게 입력해 주세요."))
        }
        guard captionSummary.isEmpty == false else { return .failure(.init(message: "팝업 소개를 입력해 주세요.")) }
        guard state.selectedRecommendIds.isEmpty == false else {
            return .failure(.init(message: "추천 카테고리를 1개 이상 선택해 주세요."))
        }
        guard state.images.isEmpty == false else {
            return .failure(.init(message: "이미지를 1개 이상 선택해 주세요."))
        }
        guard state.endDate >= state.startDate else {
            return .failure(.init(message: "종료일은 시작일보다 빠를 수 없습니다."))
        }
        guard submitterUserUuid.isEmpty == false else {
            return .failure(.init(message: "사용자 정보를 확인할 수 없습니다."))
        }

        return .success(
            PopupRequestSubmissionPayload(
                request: PopupSubmissionCreateRequest(
                    name: name,
                    startDate: state.startDate,
                    endDate: state.endDate,
                    address: state.trimmed(.address).nilIfEmpty ?? roadAddress,
                    description: captionSummary,
                    submitterUserUuid: submitterUserUuid
                )
            )
        )
    }

    func isValidWebURL(_ text: String) -> Bool {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased()
        else { return false }

        return scheme == "http" || scheme == "https"
    }

    func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
