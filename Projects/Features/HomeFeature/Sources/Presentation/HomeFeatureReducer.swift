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
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: SortButton.SortOption = .newest
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

    enum Action: Sendable {
        case onAppear
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(SortButton.SortOption)
        case toggleLike(Popup)
        case refreshFilteredPopupList
        case regionSelectionPrepared(HomeRegionSelection)
        case popupSectionsLoaded(HomePopupSections)
        case filteredPopupListLoaded([Popup])
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
    }

    @Dependencies.Dependency(\.homePopupClient) private var popupClient: HomePopupClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadAllPopupData(state: state)

            case .regionSelected(let region):
                state.selectedRegion = region
                state.selectedDistrict = region.districtList.first
                return .none

            case .districtSelected(let district):
                state.selectedDistrict = district
                state.isLoading = true
                return updatePersonalFilteredPopupList(state: state)

            case .sortOptionSelected(let option):
                state.selectedOption = option
                state.isLoading = true
                return updatePersonalFilteredPopupList(state: state)

            case .toggleLike(let popup):
                return toggleLike(state: state, popup: popup)

            case .refreshFilteredPopupList:
                state.isLoading = true
                return updatePersonalFilteredPopupList(state: state)

            case .regionSelectionPrepared(let selection):
                state.regions = selection.regions
                state.selectedRegion = selection.selectedRegion
                state.selectedDistrict = selection.selectedDistrict
                return .none

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
                let regions = state.regions.isEmpty
                    ? try await popupClient.getRegionList().sortedByHomePriority()
                    : state.regions
                let selectedRegion = state.selectedRegion ?? regions.first
                let selectedDistrict = state.selectedDistrict ?? selectedRegion?.districtList.first

                await send(.regionSelectionPrepared(HomeRegionSelection(
                    regions: regions,
                    selectedRegion: selectedRegion,
                    selectedDistrict: selectedDistrict
                )))

                async let bestPopups = popupClient.getPersonalRandomPopupList(state.userUuid)
                async let comingPopups = popupClient.getPersonalUpcomingPopupList(state.userUuid)
                async let gridPopups = popupClient.getPersonalFilteredPopupList(
                    state.userUuid,
                    selectedRegion?.region ?? "전체",
                    selectedDistrict ?? "전체",
                    state.selectedOption.rawValue
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
        let region = state.selectedRegion?.region ?? "전체"
        let district = state.selectedDistrict ?? "전체"
        let sortOption = state.selectedOption

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

struct HomePopupClient: Sendable {
    var getRegionList: @Sendable () async throws -> [RegionList]
    var getPersonalRandomPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalUpcomingPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalFilteredPopupList: @Sendable (
        _ userUuid: String,
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
}

extension HomePopupClient: DependencyKey {
    static var liveValue: HomePopupClient {
        let box = PopupUsecaseBox(DIContainer.shared.resolve(PopupUsecaseProtocol.self))

        return HomePopupClient(
            getRegionList: {
                try await box.usecase.getRegionList()
            },
            getPersonalRandomPopupList: { userUuid in
                try await box.usecase.getPersonalRandomPopupList(userUuid: userUuid)
            },
            getPersonalUpcomingPopupList: { userUuid in
                try await box.usecase.getPersonalUpcomingPopupList(userUuid: userUuid)
            },
            getPersonalFilteredPopupList: { userUuid, region, district, homeSortStandard in
                try await box.usecase.getPersonalFilteredPopupList(
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await box.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await box.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension DependencyValues {
    var homePopupClient: HomePopupClient {
        get { self[HomePopupClient.self] }
        set { self[HomePopupClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
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
