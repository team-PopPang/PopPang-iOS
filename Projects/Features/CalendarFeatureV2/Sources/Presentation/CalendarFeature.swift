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

        public init() {}
    }

    public struct CalendarPopupLoadResult: Equatable {
        let regions: [RegionList]
        let selectedRegion: RegionList?
        let selectedDistrict: String?
        let popups: [Popup]
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
        case popupDataLoaded(CalendarPopupLoadResult)
        case filteredPopupListLoaded([Popup])
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
        }
    }

    @Dependency(\.calendarFeatureClient) private var calendarFeatureClient: CalendarFeatureClient

    /// 처음 불러오기와 필터 불러오기가 함께 쓴다. 새 요청을 보내면 앞 요청을 취소해 가장 최근 조건의 응답만 반영한다.
    private enum CancelID {
        case load
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadAllPopupData(state: state)

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
                return toggleLike(state: state, popup: popup)

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .alertTapped:
                return .send(.delegate(.alertRequested))

            case .popupDataLoaded(let result):
                state.regions = result.regions
                // 불러오는 동안 사용자가 지역을 골랐으면 그 선택을 덮어쓰지 않는다.
                if state.selectedRegion == nil {
                    state.selectedRegion = result.selectedRegion
                    state.selectedDistrict = result.selectedDistrict
                }
                applyPopups(result.popups, state: &state)
                state.errorMessage = nil
                return .none

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
    func loadAllPopupData(state: State) -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient

        return .run { [state, calendarFeatureClient] send in
            do {
                let regions = state.regions.isEmpty
                    ? try await calendarFeatureClient.getRegionList().sortedByCalendarPriority()
                    : state.regions
                let selectedRegion = state.selectedRegion ?? regions.first
                let selectedDistrict = state.selectedDistrict ?? selectedRegion?.districtList.first

                let popups = try await calendarFeatureClient.getFilteredPopupList(
                    selectedRegion?.region ?? "전체",
                    selectedDistrict ?? "전체",
                    state.selectedOption.rawValue
                )

                await send(.popupDataLoaded(.init(
                    regions: regions,
                    selectedRegion: selectedRegion,
                    selectedDistrict: selectedDistrict,
                    popups: popups
                )))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
            }

            await send(.loadingChanged(false))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
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
        .cancellable(id: CancelID.load, cancelInFlight: true)
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
