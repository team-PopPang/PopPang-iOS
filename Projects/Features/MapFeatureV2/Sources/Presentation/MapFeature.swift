import ComposableArchitecture
import Core
import Domain
import Foundation

public struct MapCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 두 좌표 사이 거리(m). 지도를 옮겼을 때 다시 받을지 정할 때만 쓴다.
    func distance(to other: MapCoordinate) -> Double {
        let radius = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLng = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2)
        return radius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

/// 지도 탭. 화면은 고른 조건을 `MapPopupQuery`로 모아 서버에 보내고, 받은 결과를 그대로 그린다.
/// 목록을 앱에서 거르지 않는다.
@Reducer
public struct MapFeature {
    @ObservableState
    public struct State: Equatable {
        var popups: [Popup] = []
        var totalCount = 0
        var categories: [Recommend] = []
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var sort: MapSortOption = .closest
        var filter = MapPopupFilter()
        /// 검색어. 지도 API가 아직 받지 않아 서버에 보내지 않는다(MapAPISupport.keyword).
        var searchText = ""
        var mapCenter: MapCoordinate?
        /// 마지막으로 목록을 받은 지도 중심.
        var searchedCenter: MapCoordinate?
        var hasUserLocation = false
        /// 위치 권한을 거부했는지. 거부했으면 가까운순을 골라도 위치를 기다리지 않고 최신순으로 받는다.
        var isLocationDenied = false
        var isLoading = false
        var isWaitingForUserLocation = false
        var errorMessage: String?
        /// 미리보기 카드로 보여 주는 팝업.
        var selectedPopupUuid: String?
        /// 찜 응답을 기다리는 팝업. 응답 전에 같은 하트를 다시 누르면 무시한다(V2 찜은 중복 요청을 409·404로 거절).
        var favoriteInFlight: Set<String> = []

        public init() {}

        var selectedPopup: Popup? {
            guard let selectedPopupUuid else { return nil }
            return popups.first { $0.popupUuid == selectedPopupUuid }
        }

        var regionTitle: String {
            guard let selectedRegion, selectedRegion.region != "전체" else {
                return String(localized: "전체", bundle: .module)
            }
            guard let selectedDistrict, selectedDistrict != "전체" else { return selectedRegion.region }
            return selectedDistrict
        }

        func query(center: MapCoordinate?) -> MapPopupQuery {
            MapPopupQuery(
                region: selectedRegion?.region ?? "전체",
                district: selectedDistrict ?? "전체",
                latitude: center?.latitude,
                longitude: center?.longitude,
                sort: sort,
                filter: filter
            )
        }
    }

    public struct InitialData: Equatable, Sendable {
        let regions: [RegionList]
        let categories: [Recommend]
    }

    public enum Action {
        case onAppear
        case initialDataLoaded(InitialData)
        case searchTextChanged(String)
        case mapCenterChanged(MapCoordinate)
        case userLocationChanged(MapCoordinate)
        case locationPermissionDenied
        /// 지도 이동이 멈추고 잠깐 기다린 뒤 보낸다. 가까운순이면 그 중심으로 다시 받는다.
        case mapCenterSettled(MapCoordinate)
        case mapMarkerTapped(Popup)
        case previewDismissed
        case popupDetailTapped(Popup)
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(MapSortOption)
        case filterApplied(MapPopupFilter)
        case toggleLike(Popup)
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case favoriteRequestFinished(popupUuid: String)
        case searchResultLoaded(MapPopupSearchResult, center: MapCoordinate?)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case popupSelected(Popup)
        }
    }

    /// 가까운순에서 지도를 이만큼(m) 넘게 옮기면 그 중심으로 다시 받는다.
    static let refetchDistance: Double = 300

    private enum CancelID {
        case initialData
        case search
        case mapCenter
    }

    @Dependency(\.mapFeatureClient) private var mapFeatureClient: MapFeatureClient
    @Dependency(\.continuousClock) private var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.errorMessage = nil
                if state.regions.isEmpty {
                    state.isLoading = true
                    return loadInitialData()
                }
                return search(state: &state, center: state.mapCenter ?? state.searchedCenter)

            case .initialDataLoaded(let data):
                state.regions = data.regions
                state.categories = data.categories
                if state.selectedRegion == nil {
                    state.selectedRegion = data.regions.first
                    state.selectedDistrict = data.regions.first?.districtList.first
                }
                return search(state: &state, center: state.mapCenter)

            case .searchTextChanged(let text):
                state.searchText = text
                return .none

            case .mapCenterChanged(let coordinate):
                state.mapCenter = coordinate
                // 예전 지도처럼 가까운순일 때만 옮긴 중심으로 다시 받는다. 짧게 여러 번 움직이면 마지막 위치만 쓴다.
                // 미리보기 카드를 보는 중(목록에서 고른 팝업으로 지도를 옮긴 경우 포함)에는 다시 받지 않는다.
                guard state.sort == .closest,
                      state.selectedPopupUuid == nil,
                      state.regions.isEmpty == false,
                      (state.searchedCenter?.distance(to: coordinate) ?? .infinity) > Self.refetchDistance
                else { return .none }
                return .run { [clock] send in
                    try await clock.sleep(for: .milliseconds(400))
                    await send(.mapCenterSettled(coordinate))
                }
                .cancellable(id: CancelID.mapCenter, cancelInFlight: true)

            case .mapCenterSettled(let coordinate):
                // 기다리는 사이 마커를 고르거나 정렬을 바꿨으면 다시 받지 않는다.
                guard state.sort == .closest, state.selectedPopupUuid == nil else { return .none }
                return search(state: &state, center: coordinate)

            case .userLocationChanged(let coordinate):
                // 위치를 기다리고 있었거나 아직 한 번도 받지 않았을 때만 조회한다. 결과가 비어도 위치가 올 때마다 다시 부르지 않는다.
                let shouldSearch = state.isWaitingForUserLocation || state.searchedCenter == nil
                state.hasUserLocation = true
                state.isWaitingForUserLocation = false
                state.mapCenter = coordinate
                guard shouldSearch, state.regions.isEmpty == false else { return .none }
                return search(state: &state, center: coordinate)

            case .locationPermissionDenied:
                state.isLocationDenied = true
                state.isWaitingForUserLocation = false
                // 위치를 모르면 가까운순 대신 최신순으로 받는다. 지역 목록을 받기 전이어도 정렬은 먼저 바꿔 둔다.
                if state.sort == .closest { state.sort = .newest }
                guard state.regions.isEmpty == false else { return .none }
                return search(state: &state, center: nil)

            case .mapMarkerTapped(let popup):
                state.selectedPopupUuid = popup.popupUuid
                return .none

            case .previewDismissed:
                state.selectedPopupUuid = nil
                return .none

            case .popupDetailTapped(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .regionSelected(let region):
                state.selectedRegion = region
                state.selectedDistrict = region.districtList.first
                // 구를 고르지 않고 닫아도 목록이 고른 지역과 맞도록 바로 다시 받는다.
                return search(state: &state, center: state.mapCenter ?? state.searchedCenter)

            case .districtSelected(let district):
                state.selectedDistrict = district
                return search(state: &state, center: state.mapCenter ?? state.searchedCenter)

            case .sortOptionSelected(let option):
                state.sort = option
                return search(state: &state, center: state.mapCenter ?? state.searchedCenter)

            case .filterApplied(let filter):
                state.filter = filter
                return search(state: &state, center: state.mapCenter ?? state.searchedCenter)

            case .toggleLike(let popup):
                guard let current = state.popups.first(where: { $0.popupUuid == popup.popupUuid }),
                      state.favoriteInFlight.contains(popup.popupUuid) == false
                else { return .none }
                state.favoriteInFlight.insert(popup.popupUuid)
                return toggleLike(popup: current)

            case let .favoriteUpdated(popupUuid, isFavorited, favoriteCount):
                guard let index = state.popups.firstIndex(where: { $0.popupUuid == popupUuid }) else { return .none }
                state.popups[index].isFavorited = isFavorited
                state.popups[index].favoriteCount = favoriteCount
                return .none

            case .favoriteRequestFinished(let popupUuid):
                state.favoriteInFlight.remove(popupUuid)
                return .none

            case let .searchResultLoaded(result, center):
                state.popups = result.items
                state.totalCount = result.totalCount
                state.searchedCenter = center ?? state.searchedCenter
                state.errorMessage = nil
                if let selected = state.selectedPopupUuid,
                   result.items.contains(where: { $0.popupUuid == selected }) == false {
                    state.selectedPopupUuid = nil
                }
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .errorMessageChanged(let message):
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

extension MapFeature {
    /// 로그인이 끊긴 실패는 문구를 띄우지 않는다. 로그인 화면 전환은 AppFeature가 세션 이벤트로 한다.
    static func message(for error: Error, fallback: String) -> String? {
        error is AuthSessionError ? nil : fallback
    }

    static var loadFailedMessage: String {
        String(localized: "팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var favoriteFailedMessage: String {
        String(localized: "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }
}

private extension MapFeature {
    func loadInitialData() -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                // 카테고리는 필터 메뉴에만 쓰므로 실패해도 지도는 보여 준다.
                async let categories = (try? await mapFeatureClient.getRecommendList()) ?? []
                let regions = try await mapFeatureClient.getRegionList().sortedForMap()
                await send(.initialDataLoaded(.init(regions: regions, categories: await categories)))
            } catch {
                Logger.e("지도 지역 목록 실패: \(error)")
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
                await send(.loadingChanged(false))
            }
        }
        .cancellable(id: CancelID.initialData, cancelInFlight: true)
    }

    /// 지금 조건으로 목록을 다시 받는다. 앞선 요청은 취소해 마지막 조건의 응답만 반영한다.
    func search(state: inout State, center: MapCoordinate?) -> Effect<Action> {
        // 가까운순인데 아직 내 위치를 모르면 위치를 받은 뒤에 부른다. 지도 기본 위치(시청)로 부르지 않는다.
        // 앞서 보낸 조회는 취소해 지난 조건의 결과가 늦게 와서 목록을 바꾸지 않게 한다.
        // 위치 권한을 거부했으면 기다리지 않고 최신순으로 받는다.
        if state.sort == .closest, state.hasUserLocation == false, state.isLocationDenied {
            state.sort = .newest
        }
        if state.sort == .closest, state.hasUserLocation == false {
            state.isWaitingForUserLocation = true
            state.isLoading = false
            return .cancel(id: CancelID.search)
        }

        state.isWaitingForUserLocation = false
        state.isLoading = true
        state.errorMessage = nil
        let query = state.query(center: center)
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                var result = try await mapFeatureClient.searchMapPopups(query)
                // 가까운순 결과가 비면 서버에 최신순으로 다시 묻는다(기존 지도와 같은 동작).
                if result.items.isEmpty, query.sort == .closest {
                    var fallback = query
                    fallback.sort = .newest
                    result = try await mapFeatureClient.searchMapPopups(fallback)
                }
                await send(.searchResultLoaded(result, center: center))
            } catch is CancellationError {
                return
            } catch {
                Logger.e("지도 목록 실패: \(error)")
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
            }
            await send(.loadingChanged(false))
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }

    func toggleLike(popup: Popup) -> Effect<Action> {
        let mapFeatureClient = mapFeatureClient

        return .run { send in
            do {
                if popup.isFavorited {
                    try await mapFeatureClient.removeFavorite(popup.popupUuid)
                } else {
                    try await mapFeatureClient.addFavorite(popup.popupUuid)
                }
                await send(.favoriteUpdated(
                    popupUuid: popup.popupUuid,
                    isFavorited: !popup.isFavorited,
                    favoriteCount: popup.isFavorited ? max(0, popup.favoriteCount - 1) : popup.favoriteCount + 1
                ))
            } catch {
                Logger.e("지도 찜 실패: \(error)")
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.favoriteFailedMessage)))
            }
            await send(.favoriteRequestFinished(popupUuid: popup.popupUuid))
        }
    }
}

private extension Array where Element == RegionList {
    /// 전체, 서울을 앞에 두고 나머지는 이름순이다.
    func sortedForMap() -> [RegionList] {
        func priority(_ region: String) -> Int {
            switch region {
            case "전체": 0
            case "서울": 1
            default: 2
            }
        }
        return sorted { lhs, rhs in
            let left = priority(lhs.region)
            let right = priority(rhs.region)
            return left == right ? lhs.region < rhs.region : left < right
        }
    }
}
