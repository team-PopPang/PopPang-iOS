import ComposableArchitecture
import Core
import Domain
import DSKit
import Foundation

@Reducer
public struct CalendarFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
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

        public init(session: Shared<UserSession>) {
            self._session = session
        }

        private var currentUser: User {
            guard let user = session.user else {
                preconditionFailure("CalendarFeature requires a logged in session.")
            }
            return user
        }

        public var userUuid: String {
            currentUser.userUuid
        }
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
                return updatePersonalFilteredPopupList(
                    state: state,
                    region: state.selectedRegion?.region ?? "전체",
                    district: district,
                    sortOption: state.selectedOption
                )

            case .sortOptionSelected(let option):
                state.selectedOption = option
                state.isLoading = true
                state.errorMessage = nil
                return updatePersonalFilteredPopupList(
                    state: state,
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
                state.selectedRegion = result.selectedRegion
                state.selectedDistrict = result.selectedDistrict
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

                let popups = try await calendarFeatureClient.getPersonalFilteredPopupList(
                    state.userUuid,
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
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func updatePersonalFilteredPopupList(
        state: State,
        region: String,
        district: String,
        sortOption: SortButton.SortOption
    ) -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient

        return .run { [state, calendarFeatureClient, region, district, sortOption] send in
            do {
                let popups = try await calendarFeatureClient.getPersonalFilteredPopupList(
                    state.userUuid,
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
        let calendarFeatureClient = calendarFeatureClient
        let currentPopup = state.calendarPopups.first { $0.popupUuid == popup.popupUuid } ?? popup
        let nextFavoriteState = !currentPopup.isFavorited
        let nextFavoriteCount = nextFavoriteState
            ? currentPopup.favoriteCount + 1
            : max(0, currentPopup.favoriteCount - 1)

        return .run { [calendarFeatureClient, userUuid = state.userUuid, currentPopup, nextFavoriteState, nextFavoriteCount] send in
            do {
                if currentPopup.isFavorited {
                    try await calendarFeatureClient.removeFavorite(userUuid, currentPopup.popupUuid)
                } else {
                    try await calendarFeatureClient.addFavorite(userUuid, currentPopup.popupUuid)
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
