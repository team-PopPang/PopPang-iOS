import BottomSheet
import Compound
import Core
import Domain
import Foundation

enum MapSecondSheetType: Equatable {
    case region
    case sort
    case detail(Popup)
    case none
}

struct MapCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

enum MapSortOption: String, CaseIterable {
    case closest = "CLOSEST"
    case newest = "NEWEST"
    case closingSoon = "CLOSING_SOON"
    case mostFavorited = "MOST_FAVORITED"
    case mostViewed = "MOST_VIEWED"

    var title: String {
        switch self {
        case .closest:
            "가까운순"
        case .newest:
            "최신순"
        case .closingSoon:
            "마감순"
        case .mostFavorited:
            "찜순"
        case .mostViewed:
            "조회순"
        }
    }
}

@Compound
final class MapFeatureCompound {
    enum Action {
        case onAppear
        case refreshFilteredPopupList
        case searchTextChanged(String)
        case mapCenterChanged(MapCoordinate)
        case userLocationChanged(MapCoordinate)
        case categoryTapped(Recommend)
        case regionButtonTapped
        case sortButtonTapped
        case listButtonTapped
        case popupSelected(Popup)
        case firstSheetPositionChanged(BottomSheetPosition)
        case secondSheetPositionChanged(BottomSheetPosition)
        case dismissSecondSheet
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(MapSortOption)
        case toggleLike(Popup)
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setDidPreload(Bool)
        case setLoading(Bool)
        case setWaitingForUserLocation(Bool)
        case setMapPopups([Popup])
        case setAllPopups([Popup])
        case setCategories([Recommend])
        case setSelectedCategoryId(Int?)
        case setRegions([RegionList])
        case setSelectedRegion(RegionList?)
        case setSelectedDistrict(String?)
        case setSelectedOption(MapSortOption)
        case setSearchText(String)
        case setMapCenter(MapCoordinate?)
        case setHasUserLocation(Bool)
        case setFirstSheetPosition(BottomSheetPosition)
        case setSecondSheetPosition(BottomSheetPosition)
        case setSecondSheetType(MapSecondSheetType)
        case setFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var userUuid: String
        var mapPopups: [Popup] = []
        var allPopups: [Popup] = []
        var categories: [Recommend] = []
        var selectedCategoryId: Int?
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: MapSortOption = .closest
        var searchText = ""
        var mapCenter: MapCoordinate?
        var hasUserLocation = false
        var firstSheetPosition: BottomSheetPosition = .relative(0.5)
        var secondSheetPosition: BottomSheetPosition = .hidden
        var secondSheetType: MapSecondSheetType = .none
        var didPreload = false
        var isLoading = false
        var isWaitingForUserLocation = false
        var errorMessage: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol

    init(userUuid: String) {
        self.state = State(userUuid: userUuid)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            guard !state.didPreload else { return Self.emptyReactionStream() }

            return .concat(
                .just(.setDidPreload(true)),
                getAllPopupData()
            )

        case .refreshFilteredPopupList:
            return updatePersonalMapFilteredPopupList(
                region: state.selectedRegion?.region ?? "전체",
                district: state.selectedDistrict ?? "전체",
                mapCenter: state.mapCenter,
                sortOption: state.selectedOption
            )

        case .searchTextChanged(let text):
            return .concat(
                .just(.setSearchText(text)),
                .just(.setMapPopups(Self.filteredPopups(from: state.allPopups, searchText: text)))
            )

        case .mapCenterChanged(let coordinate):
            guard state.hasUserLocation || state.selectedOption != .closest else {
                return Self.emptyReactionStream()
            }

            let shouldRefreshEmptyInitialList = state.didPreload && state.allPopups.isEmpty

            return .concat(
                .just(.setMapCenter(coordinate)),
                shouldRefreshEmptyInitialList
                    ? updatePersonalMapFilteredPopupList(
                        region: state.selectedRegion?.region ?? "전체",
                        district: state.selectedDistrict ?? "전체",
                        mapCenter: coordinate,
                        sortOption: state.selectedOption
                    )
                    : Self.emptyReactionStream()
            )

        case .userLocationChanged(let coordinate):
            let shouldRefreshFromLocation = state.didPreload &&
                (state.selectedOption == .closest || state.allPopups.isEmpty)

            return .concat(
                .just(.setHasUserLocation(true)),
                .just(.setWaitingForUserLocation(false)),
                .just(.setMapCenter(coordinate)),
                shouldRefreshFromLocation
                    ? updatePersonalMapFilteredPopupList(
                        region: state.selectedRegion?.region ?? "전체",
                        district: state.selectedDistrict ?? "전체",
                        mapCenter: coordinate,
                        sortOption: state.selectedOption
                    )
                    : Self.emptyReactionStream()
            )

        case .categoryTapped(let category):
            if state.selectedCategoryId == category.id {
                return .concat(
                    .just(.setSelectedCategoryId(nil)),
                    .just(.setMapPopups(Self.filteredPopups(from: state.allPopups, searchText: state.searchText)))
                )
            }

            return .concat(
                .just(.setSelectedCategoryId(category.id)),
                getPopularRecommendPopupList(userUuid: state.userUuid, recommendId: category.id)
            )

        case .regionButtonTapped:
            let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
            return .concat(
                .just(.setFirstSheetPosition(firstPosition)),
                .just(.setSecondSheetType(.region)),
                .just(.setSecondSheetPosition(firstPosition))
            )

        case .sortButtonTapped:
            let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
            return .concat(
                .just(.setSecondSheetType(.sort)),
                .just(.setSecondSheetPosition(firstPosition))
            )

        case .listButtonTapped:
            return .just(.setFirstSheetPosition(.relative(0.5)))

        case .popupSelected(let popup):
            let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
            return .concat(
                .just(.setFirstSheetPosition(firstPosition)),
                .just(.setSecondSheetType(.detail(popup))),
                .just(.setSecondSheetPosition(firstPosition))
            )

        case .firstSheetPositionChanged(let position):
            return .just(.setFirstSheetPosition(position))

        case .secondSheetPositionChanged(let position):
            if position == .hidden {
                return .just(.setSecondSheetPosition(.hidden))
            }

            return .concat(
                .just(.setSecondSheetPosition(position)),
                .just(.setFirstSheetPosition(position))
            )

        case .dismissSecondSheet:
            return .concat(
                .just(.setSecondSheetPosition(.hidden)),
                .just(.setSecondSheetType(.none))
            )

        case .regionSelected(let region):
            return .concat(
                .just(.setSelectedRegion(region)),
                .just(.setSelectedDistrict(region.districtList.first))
            )

        case .districtSelected(let district):
            let selectedRegion = state.selectedRegion
            let selectedOption = state.selectedOption
            let mapCenter = state.mapCenter

            return .concat(
                .just(.setSelectedDistrict(district)),
                .just(.setSecondSheetPosition(.hidden)),
                .just(.setSecondSheetType(.none)),
                updatePersonalMapFilteredPopupList(
                    region: selectedRegion?.region ?? "전체",
                    district: district,
                    mapCenter: mapCenter,
                    sortOption: selectedOption
                )
            )

        case .sortOptionSelected(let option):
            let selectedRegion = state.selectedRegion
            let selectedDistrict = state.selectedDistrict
            let mapCenter = state.mapCenter

            return .concat(
                .just(.setSelectedOption(option)),
                .just(.setSecondSheetPosition(.hidden)),
                .just(.setSecondSheetType(.none)),
                updatePersonalMapFilteredPopupList(
                    region: selectedRegion?.region ?? "전체",
                    district: selectedDistrict ?? "전체",
                    mapCenter: mapCenter,
                    sortOption: option
                )
            )

        case .toggleLike(let popup):
            return toggleLike(popup: popup)

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setDidPreload(let didPreload):
            newState.didPreload = didPreload
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setWaitingForUserLocation(let isWaitingForUserLocation):
            newState.isWaitingForUserLocation = isWaitingForUserLocation
        case .setMapPopups(let popups):
            newState.mapPopups = popups
        case .setAllPopups(let popups):
            newState.allPopups = popups
        case .setCategories(let categories):
            newState.categories = categories
        case .setSelectedCategoryId(let categoryId):
            newState.selectedCategoryId = categoryId
        case .setRegions(let regions):
            newState.regions = regions
        case .setSelectedRegion(let region):
            newState.selectedRegion = region
        case .setSelectedDistrict(let district):
            newState.selectedDistrict = district
        case .setSelectedOption(let option):
            newState.selectedOption = option
        case .setSearchText(let text):
            newState.searchText = text
        case .setMapCenter(let coordinate):
            newState.mapCenter = coordinate
        case .setHasUserLocation(let hasUserLocation):
            newState.hasUserLocation = hasUserLocation
        case .setFirstSheetPosition(let position):
            newState.firstSheetPosition = position
        case .setSecondSheetPosition(let position):
            newState.secondSheetPosition = position
        case .setSecondSheetType(let type):
            newState.secondSheetType = type
        case .setFavorite(let popupUuid, let isFavorited, let favoriteCount):
            newState.mapPopups.updateFavorite(
                popupUuid: popupUuid,
                isFavorited: isFavorited,
                favoriteCount: favoriteCount
            )
            newState.allPopups.updateFavorite(
                popupUuid: popupUuid,
                isFavorited: isFavorited,
                favoriteCount: favoriteCount
            )
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}

private extension MapFeatureCompound {
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
                    async let regionTask = popupUsecase.getRegionList()
                    async let categoryTask = popupUsecase.getPopularRecommendList()

                    let regions = try await regionTask.sortedForMap()
                    let selectedRegion = state.selectedRegion ?? regions.first
                    let selectedDistrict = state.selectedDistrict ?? selectedRegion?.districtList.first

                    await send(.setRegions(regions))
                    await send(.setSelectedRegion(selectedRegion))
                    await send(.setSelectedDistrict(selectedDistrict))
                    await send(.setCategories(try await categoryTask))

                    if state.selectedOption == .closest && state.mapCenter == nil {
                        await send(.setWaitingForUserLocation(true))
                        return
                    }

                    let popups = try await Self.fetchMapPopups(
                        popupUsecase: popupUsecase,
                        userUuid: state.userUuid,
                        region: selectedRegion?.region ?? "전체",
                        district: selectedDistrict ?? "전체",
                        mapCenter: state.mapCenter,
                        sortOption: state.selectedOption
                    )

                    await send(.setAllPopups(popups))
                    await send(.setMapPopups(Self.filteredPopups(from: popups, searchText: state.searchText)))
                } catch {
                    Logger.e("\(error)")
                    await send(.setErrorMessage(error.localizedDescription))
                }

                if state.selectedOption != .closest || state.mapCenter != nil {
                    await send(.setLoading(false))
                }
            }
        )
    }

    func updatePersonalMapFilteredPopupList(
        region: String,
        district: String,
        mapCenter: MapCoordinate?,
        sortOption: MapSortOption
    ) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .just(.setSelectedCategoryId(nil)),
            .run { [state, popupUsecase] send in
                do {
                    let popups = try await Self.fetchMapPopups(
                        popupUsecase: popupUsecase,
                        userUuid: state.userUuid,
                        region: region,
                        district: district,
                        mapCenter: mapCenter,
                        sortOption: sortOption
                    )

                    await send(.setAllPopups(popups))
                    await send(.setMapPopups(Self.filteredPopups(from: popups, searchText: state.searchText)))
                } catch {
                    Logger.e("\(error)")
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [popupUsecase] send in
                do {
                    let popups = try await popupUsecase.getPopularRecommendPopupList(
                        userUuid: userUuid,
                        recommendId: recommendId
                    )
                    await send(.setMapPopups(popups))
                } catch {
                    Logger.e("\(error)")
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func toggleLike(popup: Popup) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .run { [state, popupUsecase] send in
            do {
                var favoriteCount = popup.favoriteCount
                let isFavorited: Bool

                if popup.isFavorited {
                    try await popupUsecase.removeFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    isFavorited = false
                    favoriteCount = max(0, favoriteCount - 1)
                } else {
                    try await popupUsecase.addFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    isFavorited = true
                    favoriteCount += 1
                }

                await send(.setFavorite(
                    popupUuid: popup.popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                ))
            } catch {
                Logger.e("\(error)")
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
    }

    static func filteredPopups(from popups: [Popup], searchText: String) -> [Popup] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return popups }

        let lowercased = trimmed.lowercased()
        return popups.filter {
            $0.name.lowercased().contains(lowercased) ||
                $0.address.lowercased().contains(lowercased)
        }
    }

    static func visibleFirstSheetPosition(from position: BottomSheetPosition) -> BottomSheetPosition {
        isFirstSheetHidden(position) ? .relative(0.5) : position
    }

    static func fetchMapPopups(
        popupUsecase: PopupUsecaseProtocol,
        userUuid: String,
        region: String,
        district: String,
        mapCenter: MapCoordinate?,
        sortOption: MapSortOption
    ) async throws -> [Popup] {
        do {
            let popups = try await popupUsecase.getPersonalMapFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                latitude: mapCenter?.latitude,
                longitude: mapCenter?.longitude,
                mapSortStandard: sortOption.rawValue
            )

            guard popups.isEmpty, sortOption == .closest else { return popups }

            return try await fetchFallbackMapPopups(
                popupUsecase: popupUsecase,
                userUuid: userUuid,
                region: region,
                district: district,
                mapCenter: mapCenter
            )
        } catch {
            guard sortOption == .closest else { throw error }

            return try await fetchFallbackMapPopups(
                popupUsecase: popupUsecase,
                userUuid: userUuid,
                region: region,
                district: district,
                mapCenter: mapCenter
            )
        }
    }

    static func fetchFallbackMapPopups(
        popupUsecase: PopupUsecaseProtocol,
        userUuid: String,
        region: String,
        district: String,
        mapCenter: MapCoordinate?
    ) async throws -> [Popup] {
        try await popupUsecase.getPersonalMapFilteredPopupList(
            userUuid: userUuid,
            region: region,
            district: district,
            latitude: mapCenter?.latitude,
            longitude: mapCenter?.longitude,
            mapSortStandard: MapSortOption.newest.rawValue
        )
    }

    static func isFirstSheetHidden(_ position: BottomSheetPosition) -> Bool {
        switch position {
        case .hidden:
            true
        case .absolute(let value):
            value == 0
        default:
            false
        }
    }
}

private extension Array where Element == RegionList {
    func sortedForMap() -> [RegionList] {
        sorted { lhs, rhs in
            if lhs.region == "전체" { return true }
            if rhs.region == "전체" { return false }
            if lhs.region == "서울" { return true }
            if rhs.region == "서울" { return false }
            return lhs.region < rhs.region
        }
    }
}

private extension Array where Element == Popup {
    mutating func updateFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int) {
        guard let index = firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        self[index].isFavorited = isFavorited
        self[index].favoriteCount = favoriteCount
    }
}
