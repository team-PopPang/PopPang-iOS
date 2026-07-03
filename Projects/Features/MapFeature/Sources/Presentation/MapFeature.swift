import BottomSheet
import ComposableArchitecture
import Core
import Domain
import Foundation

enum MapSecondSheetType: Equatable, Sendable {
    case region
    case sort
    case detail(Popup)
    case none
}

public struct MapCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum MapSortOption: String, CaseIterable, Sendable {
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

@Reducer
public struct MapFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
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
        var isLoading = false
        var isWaitingForUserLocation = false
        var errorMessage: String?

        public init(session: Shared<UserSession>) {
            self._session = session
        }

        private var currentUser: User {
            guard let user = session.user else {
                preconditionFailure("MapFeature requires a logged in session.")
            }
            return user
        }

        var userUuid: String {
            currentUser.userUuid
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.mapPopups == rhs.mapPopups
                && lhs.allPopups == rhs.allPopups
                && lhs.categories == rhs.categories
                && lhs.selectedCategoryId == rhs.selectedCategoryId
                && lhs.regions == rhs.regions
                && lhs.selectedRegion == rhs.selectedRegion
                && lhs.selectedDistrict == rhs.selectedDistrict
                && lhs.selectedOption == rhs.selectedOption
                && lhs.searchText == rhs.searchText
                && lhs.mapCenter == rhs.mapCenter
                && lhs.hasUserLocation == rhs.hasUserLocation
                && lhs.firstSheetPosition == rhs.firstSheetPosition
                && lhs.secondSheetPosition == rhs.secondSheetPosition
                && lhs.secondSheetType == rhs.secondSheetType
                && lhs.isLoading == rhs.isLoading
                && lhs.isWaitingForUserLocation == rhs.isWaitingForUserLocation
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public struct InitialData: Equatable, Sendable {
        let regions: [RegionList]
        let selectedRegion: RegionList?
        let selectedDistrict: String?
        let categories: [Recommend]

        public init(
            regions: [RegionList],
            selectedRegion: RegionList?,
            selectedDistrict: String?,
            categories: [Recommend]
        ) {
            self.regions = regions
            self.selectedRegion = selectedRegion
            self.selectedDistrict = selectedDistrict
            self.categories = categories
        }
    }

    public enum Action {
        case onAppear
        case searchTextChanged(String)
        case mapCenterChanged(MapCoordinate)
        case userLocationChanged(MapCoordinate)
        case locationPermissionDenied
        case categoryTapped(Recommend)
        case regionButtonTapped
        case sortButtonTapped
        case listButtonTapped
        case popupPreviewRequested(Popup)
        case mapMarkerTapped(Popup)
        case popupDetailTapped(Popup)
        case firstSheetPositionChanged(BottomSheetPosition)
        case secondSheetPositionChanged(BottomSheetPosition)
        case dismissSecondSheet
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(MapSortOption)
        case toggleLike(Popup)
        case initialDataLoaded(InitialData)
        case mapPopupListLoaded([Popup])
        case categoryPopupListLoaded([Popup], Int)
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case loadingChanged(Bool)
        case waitingForUserLocationChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case popupSelected(Popup)
        }
    }

    @Dependency(\.mapFeatureClient) private var mapFeatureClient: MapFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadAllPopupData(state: state)

            case .searchTextChanged(let text):
                state.searchText = text
                state.mapPopups = Self.filteredPopups(
                    from: state.allPopups,
                    searchText: text
                )
                return .none

            case .mapCenterChanged(let coordinate):
                guard state.hasUserLocation || state.selectedOption != .closest else {
                    return .none
                }

                state.mapCenter = coordinate

                guard state.allPopups.isEmpty else {
                    return .none
                }

                state.isLoading = true
                return updatePersonalMapFilteredPopupList(
                    userUuid: state.userUuid,
                    region: state.selectedRegion?.region ?? "전체",
                    district: state.selectedDistrict ?? "전체",
                    mapCenter: coordinate,
                    sortOption: state.selectedOption
                )

            case .userLocationChanged(let coordinate):
                let shouldRefreshFromLocation = state.isWaitingForUserLocation || state.allPopups.isEmpty
                state.hasUserLocation = true
                state.isWaitingForUserLocation = false
                state.mapCenter = coordinate

                guard shouldRefreshFromLocation else {
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                return updatePersonalMapFilteredPopupList(
                    userUuid: state.userUuid,
                    region: state.selectedRegion?.region ?? "전체",
                    district: state.selectedDistrict ?? "전체",
                    mapCenter: coordinate,
                    sortOption: state.selectedOption
                )

            case .locationPermissionDenied:
                state.isWaitingForUserLocation = false
                state.isLoading = false
                return .none

            case .categoryTapped(let category):
                if state.selectedCategoryId == category.id {
                    state.selectedCategoryId = nil
                    state.mapPopups = Self.filteredPopups(
                        from: state.allPopups,
                        searchText: state.searchText
                    )
                    return .none
                }

                state.selectedCategoryId = category.id
                state.isLoading = true
                state.errorMessage = nil
                return loadPopularRecommendPopupList(
                    userUuid: state.userUuid,
                    recommendId: category.id
                )

            case .regionButtonTapped:
                let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
                state.firstSheetPosition = firstPosition
                state.secondSheetType = .region
                state.secondSheetPosition = firstPosition
                return .none

            case .sortButtonTapped:
                let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
                state.secondSheetType = .sort
                state.secondSheetPosition = firstPosition
                return .none

            case .listButtonTapped:
                state.firstSheetPosition = .relative(0.5)
                return .none

            case .popupPreviewRequested(let popup):
                let firstPosition = Self.visibleFirstSheetPosition(from: state.firstSheetPosition)
                state.firstSheetPosition = firstPosition
                state.secondSheetType = .detail(popup)
                state.secondSheetPosition = firstPosition
                return .none

            case .mapMarkerTapped(let popup),
                    .popupDetailTapped(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .firstSheetPositionChanged(let position):
                state.firstSheetPosition = position
                return .none

            case .secondSheetPositionChanged(let position):
                if position == .hidden {
                    state.secondSheetPosition = .hidden
                } else {
                    state.secondSheetPosition = position
                    state.firstSheetPosition = position
                }
                return .none

            case .dismissSecondSheet:
                state.secondSheetPosition = .hidden
                state.secondSheetType = .none
                return .none

            case .regionSelected(let region):
                state.selectedRegion = region
                state.selectedDistrict = region.districtList.first
                return .none

            case .districtSelected(let district):
                state.selectedDistrict = district
                state.selectedCategoryId = nil
                state.secondSheetPosition = .hidden
                state.secondSheetType = .none
                state.isLoading = true
                state.errorMessage = nil
                return updatePersonalMapFilteredPopupList(
                    userUuid: state.userUuid,
                    region: state.selectedRegion?.region ?? "전체",
                    district: district,
                    mapCenter: state.mapCenter,
                    sortOption: state.selectedOption
                )

            case .sortOptionSelected(let option):
                state.selectedOption = option
                state.selectedCategoryId = nil
                state.secondSheetPosition = .hidden
                state.secondSheetType = .none
                state.isLoading = true
                state.errorMessage = nil
                return updatePersonalMapFilteredPopupList(
                    userUuid: state.userUuid,
                    region: state.selectedRegion?.region ?? "전체",
                    district: state.selectedDistrict ?? "전체",
                    mapCenter: state.mapCenter,
                    sortOption: option
                )

            case .toggleLike(let popup):
                return toggleLike(
                    userUuid: state.userUuid,
                    popup: popup
                )

            case .initialDataLoaded(let result):
                state.regions = result.regions
                state.selectedRegion = result.selectedRegion
                state.selectedDistrict = result.selectedDistrict
                state.categories = result.categories
                return .none

            case .mapPopupListLoaded(let popups):
                state.allPopups = popups
                state.mapPopups = Self.filteredPopups(
                    from: popups,
                    searchText: state.searchText
                )
                state.errorMessage = nil
                return .none

            case .categoryPopupListLoaded(let popups, let categoryId):
                state.selectedCategoryId = categoryId
                state.mapPopups = popups
                state.errorMessage = nil
                return .none

            case let .favoriteUpdated(popupUuid, isFavorited, favoriteCount):
                state.mapPopups.updateFavorite(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                state.allPopups.updateFavorite(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .waitingForUserLocationChanged(let isWaitingForUserLocation):
                if isWaitingForUserLocation,
                   state.hasUserLocation || state.mapCenter != nil || state.allPopups.isEmpty == false {
                    return .none
                }
                state.isWaitingForUserLocation = isWaitingForUserLocation
                return .none

            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension MapFeature {
    func loadAllPopupData(state: State) -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient
        let existingRegions = state.regions
        let selectedRegion = state.selectedRegion
        let selectedDistrict = state.selectedDistrict
        let selectedOption = state.selectedOption
        let mapCenter = state.mapCenter
        let userUuid = state.userUuid

        return .run { send in
            do {
                async let categoriesTask = mapFeatureClient.getPopularRecommendList()

                let regions = existingRegions.isEmpty
                    ? try await mapFeatureClient.getRegionList().sortedForMap()
                    : existingRegions

                let resolvedSelectedRegion = selectedRegion ?? regions.first
                let resolvedSelectedDistrict = selectedDistrict ?? resolvedSelectedRegion?.districtList.first

                await send(.initialDataLoaded(.init(
                    regions: regions,
                    selectedRegion: resolvedSelectedRegion,
                    selectedDistrict: resolvedSelectedDistrict,
                    categories: try await categoriesTask
                )))

                if selectedOption == .closest, mapCenter == nil {
                    await send(.waitingForUserLocationChanged(true))
                    return
                }

                let popups = try await Self.fetchMapPopups(
                    mapFeatureClient: mapFeatureClient,
                    userUuid: userUuid,
                    region: resolvedSelectedRegion?.region ?? "전체",
                    district: resolvedSelectedDistrict ?? "전체",
                    mapCenter: mapCenter,
                    sortOption: selectedOption
                )

                await send(.mapPopupListLoaded(popups))
            } catch {
                Logger.e("\(error)")
                await send(.errorMessageChanged(error.localizedDescription))
            }

            if selectedOption != .closest || mapCenter != nil {
                await send(.loadingChanged(false))
            }
        }
    }

    func updatePersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        mapCenter: MapCoordinate?,
        sortOption: MapSortOption
    ) -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                let popups = try await Self.fetchMapPopups(
                    mapFeatureClient: mapFeatureClient,
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    mapCenter: mapCenter,
                    sortOption: sortOption
                )

                await send(.mapPopupListLoaded(popups))
            } catch {
                Logger.e("\(error)")
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func loadPopularRecommendPopupList(
        userUuid: String,
        recommendId: Int
    ) -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                let popups = try await mapFeatureClient.getPopularRecommendPopupList(
                    userUuid,
                    recommendId
                )
                await send(.categoryPopupListLoaded(popups, recommendId))
            } catch {
                Logger.e("\(error)")
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func toggleLike(
        userUuid: String,
        popup: Popup
    ) -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                var favoriteCount = popup.favoriteCount
                let isFavorited: Bool

                if popup.isFavorited {
                    try await mapFeatureClient.removeFavorite(userUuid, popup.popupUuid)
                    isFavorited = false
                    favoriteCount = max(0, favoriteCount - 1)
                } else {
                    try await mapFeatureClient.addFavorite(userUuid, popup.popupUuid)
                    isFavorited = true
                    favoriteCount += 1
                }

                await send(.favoriteUpdated(
                    popupUuid: popup.popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                ))
            } catch {
                Logger.e("\(error)")
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    static func filteredPopups(from popups: [Popup], searchText: String) -> [Popup] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return popups }

        let lowercased = trimmed.lowercased()
        return popups.filter {
            $0.name.lowercased().contains(lowercased)
                || $0.address.lowercased().contains(lowercased)
        }
    }

    static func visibleFirstSheetPosition(from position: BottomSheetPosition) -> BottomSheetPosition {
        isFirstSheetHidden(position) ? .relative(0.5) : position
    }

    static func fetchMapPopups(
        mapFeatureClient: MapFeatureClient,
        userUuid: String,
        region: String,
        district: String,
        mapCenter: MapCoordinate?,
        sortOption: MapSortOption
    ) async throws -> [Popup] {
        do {
            let popups = try await mapFeatureClient.getPersonalMapFilteredPopupList(
                userUuid,
                region,
                district,
                mapCenter?.latitude,
                mapCenter?.longitude,
                sortOption.rawValue
            )

            guard popups.isEmpty, sortOption == .closest else { return popups }

            return try await fetchFallbackMapPopups(
                mapFeatureClient: mapFeatureClient,
                userUuid: userUuid,
                region: region,
                district: district,
                mapCenter: mapCenter
            )
        } catch {
            guard sortOption == .closest else { throw error }

            return try await fetchFallbackMapPopups(
                mapFeatureClient: mapFeatureClient,
                userUuid: userUuid,
                region: region,
                district: district,
                mapCenter: mapCenter
            )
        }
    }

    static func fetchFallbackMapPopups(
        mapFeatureClient: MapFeatureClient,
        userUuid: String,
        region: String,
        district: String,
        mapCenter: MapCoordinate?
    ) async throws -> [Popup] {
        try await mapFeatureClient.getPersonalMapFilteredPopupList(
            userUuid,
            region,
            district,
            mapCenter?.latitude,
            mapCenter?.longitude,
            MapSortOption.newest.rawValue
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
    mutating func updateFavorite(
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        guard let index = firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        self[index].isFavorited = isFavorited
        self[index].favoriteCount = favoriteCount
    }
}
