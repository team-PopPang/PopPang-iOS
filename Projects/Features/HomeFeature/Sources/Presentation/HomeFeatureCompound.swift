import Compound
import Domain
import DSKit
import Foundation

@Compound
final class HomeFeatureCompound {
    enum Action {
        case onAppear
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(SortButton.SortOption)
        case toggleLike(Popup)
        case refreshFilteredPopupList
    }

    enum Reaction {
        case setDidPreload(Bool)
        case setLoading(Bool)
        case setErrorMessage(String?)
        case setBestPopups([Popup])
        case setComingPopups([Popup])
        case setGridPopups([Popup])
        case setRegions([RegionList])
        case setSelectedRegion(RegionList?)
        case setSelectedDistrict(String?)
        case setSelectedOption(SortButton.SortOption)
        case setFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
    }

    struct State: Equatable {
        var userUuid: String
        var nickname: String
        var bestPopups: [Popup] = []
        var comingPopups: [Popup] = []
        var gridPopups: [Popup] = []
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: SortButton.SortOption = .newest
        var didPreload = false
        var isLoading = false
        var errorMessage: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol

    init(
        userUuid: String,
        nickname: String
    ) {
        self.state = State(userUuid: userUuid, nickname: nickname)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            guard !state.didPreload else { return Self.emptyReactionStream() }

            return .concat(
                .just(.setDidPreload(true)),
                getAllPopupData()
            )

        case .regionSelected(let region):
            return .concat(
                .just(.setSelectedRegion(region)),
                .just(.setSelectedDistrict(region.districtList.first))
            )

        case .districtSelected(let district):
            let selectedRegion = state.selectedRegion
            let selectedOption = state.selectedOption
            return .concat(
                .just(.setSelectedDistrict(district)),
                updatePersonalFilteredPopupList(
                    region: selectedRegion?.region ?? "전체",
                    district: district,
                    sortOption: selectedOption
                )
            )

        case .sortOptionSelected(let option):
            let selectedRegion = state.selectedRegion
            let selectedDistrict = state.selectedDistrict
            return .concat(
                .just(.setSelectedOption(option)),
                updatePersonalFilteredPopupList(
                    region: selectedRegion?.region ?? "전체",
                    district: selectedDistrict ?? "전체",
                    sortOption: option
                )
            )

        case .toggleLike(let popup):
            return toggleLike(popup: popup)

        case .refreshFilteredPopupList:
            return updatePersonalFilteredPopupList(
                region: state.selectedRegion?.region ?? "전체",
                district: state.selectedDistrict ?? "전체",
                sortOption: state.selectedOption
            )
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setDidPreload(let didPreload):
            newState.didPreload = didPreload

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage

        case .setBestPopups(let popups):
            newState.bestPopups = popups

        case .setComingPopups(let popups):
            newState.comingPopups = popups.sorted { $0.startDate < $1.startDate }

        case .setGridPopups(let popups):
            newState.gridPopups = popups

        case .setRegions(let regions):
            newState.regions = regions

        case .setSelectedRegion(let region):
            newState.selectedRegion = region

        case .setSelectedDistrict(let district):
            newState.selectedDistrict = district

        case .setSelectedOption(let option):
            newState.selectedOption = option

        case let .setFavorite(popupUuid, isFavorited, favoriteCount):
            for index in newState.gridPopups.indices where newState.gridPopups[index].popupUuid == popupUuid {
                newState.gridPopups[index].isFavorited = isFavorited
                newState.gridPopups[index].favoriteCount = favoriteCount
            }
        }

        return newState
    }
}

private extension HomeFeatureCompound {
    static func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func getAllPopupData() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [state, popupUsecase] send in
                do {
                    let regions = state.regions.isEmpty
                        ? try await popupUsecase.getRegionList().sortedByHomePriority()
                        : state.regions
                    let selectedRegion = state.selectedRegion ?? regions.first
                    let selectedDistrict = state.selectedDistrict ?? selectedRegion?.districtList.first

                    await send(.setRegions(regions))
                    await send(.setSelectedRegion(selectedRegion))
                    await send(.setSelectedDistrict(selectedDistrict))

                    async let bestPopups = popupUsecase.getPersonalRandomPopupList(userUuid: state.userUuid)
                    async let comingPopups = popupUsecase.getPersonalUpcomingPopupList(userUuid: state.userUuid)
                    async let gridPopups = popupUsecase.getPersonalFilteredPopupList(
                        userUuid: state.userUuid,
                        region: selectedRegion?.region ?? "전체",
                        district: selectedDistrict ?? "전체",
                        homeSortStandard: state.selectedOption.rawValue
                    )

                    await send(.setBestPopups(try await bestPopups))
                    await send(.setComingPopups(try await comingPopups))
                    await send(.setGridPopups(try await gridPopups))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func updatePersonalFilteredPopupList(
        region: String,
        district: String,
        sortOption: SortButton.SortOption
    ) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .run { [state, popupUsecase] send in
                do {
                    let popups = try await popupUsecase.getPersonalFilteredPopupList(
                        userUuid: state.userUuid,
                        region: region,
                        district: district,
                        homeSortStandard: sortOption.rawValue
                    )
                    await send(.setGridPopups(popups))
                    await send(.setErrorMessage(nil))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func toggleLike(popup: Popup) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .run { [state, popupUsecase] send in
            let currentPopup = state.gridPopups.first { $0.popupUuid == popup.popupUuid } ?? popup
            let nextFavoriteState = !currentPopup.isFavorited

            do {
                if currentPopup.isFavorited {
                    try await popupUsecase.removeFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                } else {
                    try await popupUsecase.addFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                }

                let nextFavoriteCount = nextFavoriteState
                    ? currentPopup.favoriteCount + 1
                    : max(0, currentPopup.favoriteCount - 1)
                await send(
                    .setFavorite(
                        popupUuid: popup.popupUuid,
                        isFavorited: nextFavoriteState,
                        favoriteCount: nextFavoriteCount
                    )
                )
                await send(.setErrorMessage(nil))
            } catch {
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
    }
}

private extension [RegionList] {
    func sortedByHomePriority() -> [RegionList] {
        sorted { lhs, rhs in
            if lhs.region == "전체" { return true }
            if rhs.region == "전체" { return false }
            if lhs.region == "서울" { return true }
            if rhs.region == "서울" { return false }
            return false
        }
    }
}
