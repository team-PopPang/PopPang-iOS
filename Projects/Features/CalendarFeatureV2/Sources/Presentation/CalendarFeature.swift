import ComposableArchitecture
import Core
import Domain
import DSKit
import Foundation

@Reducer
public struct CalendarFeature {
    @ObservableState
    public struct State: Equatable {
        public var calendarPopups: [Popup] = []
        public var selectedDate: Date = Date()
        public var selectedPopups: [Popup] = []
        public var popupEventCounts: [Date: Int] = [:]
        public var regions: [RegionList] = []
        public var selectedRegion: RegionList?
        public var selectedDistrict: String?
        public var selectedOption: SortButton.SortOption = .newest
        public var isLoading = false
        public var errorMessage: String?
        /// 찜 요청을 보내고 응답을 기다리는 팝업. 응답 전에 같은 하트를 다시 누르면 무시한다.
        /// V2 찜은 같은 요청을 두 번 보내면 409·404로 거절하므로 중복 요청을 막는다.
        public var favoriteInFlight: Set<String> = []

        public init() {}
    }

    public enum Action {
        case onAppear
        case dateSelected(Date)
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(SortButton.SortOption)
        case toggleLike(Popup)
        case popupSelected(Popup)
        case alertTapped
        case regionsLoaded([RegionList])
        case filteredPopupListLoaded([Popup])
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case favoriteRequestFinished(popupUuid: String)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
        }
    }

    @Dependency(\.calendarFeatureClient) private var calendarFeatureClient: CalendarFeatureClient

    /// 지역 목록과 팝업 목록 요청을 나눠 취소한다.
    /// 팝업 목록은 모두 `popups` 하나로 보내므로, 새 요청이 앞 요청을 취소해 가장 최근 조건의 응답만 반영한다.
    /// 지역 목록은 팝업 요청에 취소되지 않아, 첫 화면에서 정렬을 먼저 바꿔도 지역을 받는다.
    private enum CancelID {
        case regions
        case popups
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                if state.regions.isEmpty {
                    return loadRegions()
                }
                return loadCurrentPopups(state: state)

            case .dateSelected(let date):
                state.selectedDate = date
                state.selectedPopups = Self.popups(from: state.calendarPopups, on: date)
                return .none

            case .regionSelected(let region):
                state.selectedRegion = region
                state.selectedDistrict = region.districtList.first
                return .none

            case .districtSelected(let district):
                state.selectedDistrict = district
                state.isLoading = true
                state.errorMessage = nil
                return updateFilteredPopupList(
                    region: state.selectedRegion?.region ?? "전체",
                    district: district,
                    sortOption: state.selectedOption
                )

            case .sortOptionSelected(let option):
                state.selectedOption = option
                state.isLoading = true
                state.errorMessage = nil
                return updateFilteredPopupList(
                    region: state.selectedRegion?.region ?? "전체",
                    district: state.selectedDistrict ?? "전체",
                    sortOption: option
                )

            case .toggleLike(let popup):
                guard !state.favoriteInFlight.contains(popup.popupUuid) else { return .none }
                state.favoriteInFlight.insert(popup.popupUuid)
                return toggleLike(state: state, popup: popup)

            case .favoriteRequestFinished(let popupUuid):
                state.favoriteInFlight.remove(popupUuid)
                return .none

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .alertTapped:
                return .send(.delegate(.alertRequested))

            case .regionsLoaded(let regions):
                state.regions = regions
                if state.selectedRegion == nil {
                    state.selectedRegion = regions.first
                    state.selectedDistrict = regions.first?.districtList.first
                }
                // 팝업은 지역을 받은 뒤 지금 선택으로 받는다. 그사이 사용자가 바꾼 정렬도 반영된다.
                state.isLoading = true
                return loadCurrentPopups(state: state)

            case .filteredPopupListLoaded(let popups):
                applyPopups(popups, state: &state)
                state.errorMessage = nil
                return .none

            case let .favoriteUpdated(popupUuid, isFavorited, favoriteCount):
                updateFavorite(
                    in: &state.calendarPopups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                updateFavorite(
                    in: &state.selectedPopups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                // 앞선 찜 실패 문구만 지운다. 불러오기 실패 문구는 그대로 둔다.
                if state.errorMessage == Self.favoriteFailedMessage {
                    state.errorMessage = nil
                }
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
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

extension CalendarFeature {
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

private extension CalendarFeature {
    func loadRegions() -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient

        return .run { [calendarFeatureClient] send in
            do {
                let regions = try await calendarFeatureClient.getRegionList().sortedByCalendarPriority()
                await send(.regionsLoaded(regions))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
                await send(.loadingChanged(false))
            }
        }
        .cancellable(id: CancelID.regions, cancelInFlight: true)
    }

    func loadCurrentPopups(state: State) -> Effect<Action> {
        updateFilteredPopupList(
            region: state.selectedRegion?.region ?? "전체",
            district: state.selectedDistrict ?? "전체",
            sortOption: state.selectedOption
        )
    }

    func updateFilteredPopupList(
        region: String,
        district: String,
        sortOption: SortButton.SortOption
    ) -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient

        return .run { [calendarFeatureClient, region, district, sortOption] send in
            do {
                let popups = try await calendarFeatureClient.getFilteredPopupList(
                    region,
                    district,
                    sortOption.rawValue
                )
                await send(.filteredPopupListLoaded(popups))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
            }

            await send(.loadingChanged(false))
        }
        .cancellable(id: CancelID.popups, cancelInFlight: true)
    }

    func toggleLike(state: State, popup: Popup) -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient
        let currentPopup = state.calendarPopups.first { $0.popupUuid == popup.popupUuid } ?? popup
        let nextFavoriteState = !currentPopup.isFavorited
        let nextFavoriteCount = nextFavoriteState
            ? currentPopup.favoriteCount + 1
            : max(0, currentPopup.favoriteCount - 1)

        return .run { [calendarFeatureClient, currentPopup, nextFavoriteState, nextFavoriteCount] send in
            do {
                if currentPopup.isFavorited {
                    try await calendarFeatureClient.removeFavorite(currentPopup.popupUuid)
                } else {
                    try await calendarFeatureClient.addFavorite(currentPopup.popupUuid)
                }

                await send(.favoriteUpdated(
                    popupUuid: currentPopup.popupUuid,
                    isFavorited: nextFavoriteState,
                    favoriteCount: nextFavoriteCount
                ))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.favoriteFailedMessage)))
            }
            await send(.favoriteRequestFinished(popupUuid: currentPopup.popupUuid))
        }
    }

    func applyPopups(_ popups: [Popup], state: inout State) {
        state.calendarPopups = popups
        state.popupEventCounts = Self.eventCounts(from: popups)
        state.selectedPopups = Self.popups(from: popups, on: state.selectedDate)
    }

    func updateFavorite(
        in popups: inout [Popup],
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        guard let index = popups.firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        popups[index].isFavorited = isFavorited
        popups[index].favoriteCount = favoriteCount
    }

    static func eventCounts(from popups: [Popup]) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current

        for popup in popups {
            var date = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)

            while date <= end {
                counts[date, default: 0] += 1
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
                date = nextDate
            }
        }

        return counts
    }

    static func popups(from popups: [Popup], on date: Date) -> [Popup] {
        popups.filter { popup in
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)
            let target = calendar.startOfDay(for: date)
            return target >= start && target <= end
        }
    }
}

private extension [RegionList] {
    func sortedByCalendarPriority() -> [RegionList] {
        sorted { lhs, rhs in
            if lhs.region == "전체" { return true }
            if rhs.region == "전체" { return false }
            if lhs.region == "서울" { return true }
            if rhs.region == "서울" { return false }
            return false
        }
    }
}
