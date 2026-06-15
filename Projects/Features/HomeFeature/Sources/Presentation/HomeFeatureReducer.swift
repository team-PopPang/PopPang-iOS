import ComposableArchitecture
import Domain
import DSKit
import Foundation

@Reducer
struct HomeFeatureReducer {
    @ObservableState
    struct State: Equatable, Sendable {
        var userUuid: String
        var nickname: String
        var bestPopups: [Popup] = []
        var comingPopups: [Popup] = []
        var gridPopups: [Popup] = []
        var filter = HomeFilterReducer.State()
        var isLoading = false
        var errorMessage: String?

        init(
            userUuid: String,
            nickname: String
        ) {
            self.userUuid = userUuid
            self.nickname = nickname
        }
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case filter(HomeFilterReducer.Action)
        case toggleLike(Popup)
        case refreshFilteredPopupList
        case popupSectionsLoaded(HomePopupSections)
        case filteredPopupListLoaded([Popup])
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
    }

    @Dependencies.Dependency(\.homePopupClient) private var popupClient: HomePopupClient

    var body: some Reducer<State, Action> {
        Scope(state: \.filter, action: \.filter) {
            HomeFilterReducer()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadAllPopupData(state: state)

            case .filter(.districtSelected), .filter(.sortOptionSelected):
                state.isLoading = true
                return updatePersonalFilteredPopupList(state: state)

            case .filter:
                return .none

            case .toggleLike(let popup):
                return toggleLike(state: state, popup: popup)

            case .refreshFilteredPopupList:
                state.isLoading = true
                return updatePersonalFilteredPopupList(state: state)

            case .popupSectionsLoaded(let sections):
                state.bestPopups = sections.bestPopups
                state.comingPopups = sections.comingPopups.sorted { $0.startDate < $1.startDate }
                state.gridPopups = sections.gridPopups
                state.errorMessage = nil
                return .none

            case .filteredPopupListLoaded(let popups):
                state.gridPopups = popups
                state.errorMessage = nil
                return .none

            case let .favoriteUpdated(popupUuid, isFavorited, favoriteCount):
                updateFavorite(
                    in: &state.bestPopups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                updateFavorite(
                    in: &state.comingPopups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                updateFavorite(
                    in: &state.gridPopups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none
            }
        }
    }
}

private extension HomeFeatureReducer {
    func loadAllPopupData(state: State) -> Effect<Action> {
        let popupClient = popupClient

        return .run { [state, popupClient] send in
            do {
                let regions = state.filter.regions.isEmpty
                    ? try await popupClient.getRegionList().sortedByHomePriority()
                    : state.filter.regions
                let selectedRegion = state.filter.selectedRegion ?? regions.first
                let selectedDistrict = state.filter.selectedDistrict ?? selectedRegion?.districtList.first

                await send(.filter(.regionSelectionPrepared(HomeRegionSelection(
                    regions: regions,
                    selectedRegion: selectedRegion,
                    selectedDistrict: selectedDistrict
                ))))

                async let bestPopups = popupClient.getPersonalRandomPopupList(state.userUuid)
                async let comingPopups = popupClient.getPersonalUpcomingPopupList(state.userUuid)
                async let gridPopups = popupClient.getPersonalFilteredPopupList(
                    state.userUuid,
                    selectedRegion?.region ?? "전체",
                    selectedDistrict ?? "전체",
                    state.filter.selectedOption.rawValue
                )

                await send(.popupSectionsLoaded(HomePopupSections(
                    bestPopups: try await bestPopups,
                    comingPopups: try await comingPopups,
                    gridPopups: try await gridPopups
                )))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func updatePersonalFilteredPopupList(state: State) -> Effect<Action> {
        let popupClient = popupClient
        let userUuid = state.userUuid
        let region = state.filter.selectedRegion?.region ?? "전체"
        let district = state.filter.selectedDistrict ?? "전체"
        let sortOption = state.filter.selectedOption

        return .run { [popupClient, userUuid, region, district, sortOption] send in
            do {
                let popups = try await popupClient.getPersonalFilteredPopupList(
                    userUuid,
                    region,
                    district,
                    sortOption.rawValue
                )
                await send(.filteredPopupListLoaded(popups))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func toggleLike(state: State, popup: Popup) -> Effect<Action> {
        let popupClient = popupClient
        let currentPopup = currentPopup(in: state, matching: popup)
        let nextFavoriteState = !currentPopup.isFavorited
        let nextFavoriteCount = nextFavoriteState
            ? currentPopup.favoriteCount + 1
            : max(0, currentPopup.favoriteCount - 1)

        return .run { [popupClient, userUuid = state.userUuid, currentPopup, nextFavoriteState, nextFavoriteCount] send in
            do {
                if currentPopup.isFavorited {
                    try await popupClient.removeFavorite(userUuid, currentPopup.popupUuid)
                } else {
                    try await popupClient.addFavorite(userUuid, currentPopup.popupUuid)
                }

                await send(.favoriteUpdated(
                    popupUuid: currentPopup.popupUuid,
                    isFavorited: nextFavoriteState,
                    favoriteCount: nextFavoriteCount
                ))
                await send(.errorMessageChanged(nil))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func currentPopup(in state: State, matching popup: Popup) -> Popup {
        state.gridPopups.first { $0.popupUuid == popup.popupUuid }
            ?? state.comingPopups.first { $0.popupUuid == popup.popupUuid }
            ?? state.bestPopups.first { $0.popupUuid == popup.popupUuid }
            ?? popup
    }

    func updateFavorite(
        in popups: inout [Popup],
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        for index in popups.indices where popups[index].popupUuid == popupUuid {
            popups[index].isFavorited = isFavorited
            popups[index].favoriteCount = favoriteCount
        }
    }
}

struct HomeRegionSelection: Equatable, Sendable {
    var regions: [RegionList]
    var selectedRegion: RegionList?
    var selectedDistrict: String?
}

struct HomePopupSections: Equatable, Sendable {
    var bestPopups: [Popup]
    var comingPopups: [Popup]
    var gridPopups: [Popup]
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
