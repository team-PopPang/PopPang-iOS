import Compound
import Domain
import DSKit
import Foundation

@Compound
final class CalendarFeatureCompound {
    enum SheetRoute: String, Identifiable, Sendable {
        case region
        case sort

        var id: String { rawValue }
    }

    enum Action {
        case onAppear
        case dateSelected(Date)
        case regionSheetPresented(Bool)
        case sortSheetPresented(Bool)
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(SortButton.SortOption)
        case toggleLike(Popup)
        case refreshFilteredPopupList
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setLoading(Bool)
        case setCalendarPopups([Popup])
        case setSelectedDate(Date)
        case setSelectedPopups([Popup])
        case setPopupEventCounts([Date: Int])
        case setRegions([RegionList])
        case setSelectedRegion(RegionList?)
        case setSelectedDistrict(String?)
        case setSelectedOption(SortButton.SortOption)
        case presentSheet(SheetRoute?)
        case setFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var userUuid: String
        var calendarPopups: [Popup] = []
        var selectedDate: Date = Date()
        var selectedPopups: [Popup] = []
        var popupEventCounts: [Date: Int] = [:]
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: SortButton.SortOption = .newest
        @Trigger var presentedSheet: SheetRoute?
        var isLoading = false
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
            return getAllPopupData()

        case .dateSelected(let date):
            return .concat(
                .just(.setSelectedDate(date)),
                .just(.setSelectedPopups(Self.popups(from: state.calendarPopups, on: date)))
            )

        case .regionSheetPresented(let isPresented):
            return isPresented ? .just(.presentSheet(.region)) : Self.emptyReactionStream()

        case .sortSheetPresented(let isPresented):
            return isPresented ? .just(.presentSheet(.sort)) : Self.emptyReactionStream()

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

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setCalendarPopups(let popups):
            newState.calendarPopups = popups
        case .setSelectedDate(let date):
            newState.selectedDate = date
        case .setSelectedPopups(let popups):
            newState.selectedPopups = popups
        case .setPopupEventCounts(let counts):
            newState.popupEventCounts = counts
        case .setRegions(let regions):
            newState.regions = regions
        case .setSelectedRegion(let region):
            newState.selectedRegion = region
        case .setSelectedDistrict(let district):
            newState.selectedDistrict = district
        case .setSelectedOption(let option):
            newState.selectedOption = option
        case .presentSheet(let sheet):
            newState.presentedSheet = sheet
        case let .setFavorite(popupUuid, isFavorited, favoriteCount):
            for index in newState.calendarPopups.indices where newState.calendarPopups[index].popupUuid == popupUuid {
                newState.calendarPopups[index].isFavorited = isFavorited
                newState.calendarPopups[index].favoriteCount = favoriteCount
            }
            for index in newState.selectedPopups.indices where newState.selectedPopups[index].popupUuid == popupUuid {
                newState.selectedPopups[index].isFavorited = isFavorited
                newState.selectedPopups[index].favoriteCount = favoriteCount
            }
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}

private extension CalendarFeatureCompound {
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
                        ? try await popupUsecase.getRegionList().sortedByCalendarPriority()
                        : state.regions
                    let selectedRegion = state.selectedRegion ?? regions.first
                    let selectedDistrict = state.selectedDistrict ?? selectedRegion?.districtList.first

                    await send(.setRegions(regions))
                    await send(.setSelectedRegion(selectedRegion))
                    await send(.setSelectedDistrict(selectedDistrict))

                    let popups = try await popupUsecase.getPersonalFilteredPopupList(
                        userUuid: state.userUuid,
                        region: selectedRegion?.region ?? "전체",
                        district: selectedDistrict ?? "전체",
                        homeSortStandard: state.selectedOption.rawValue
                    )
                    await send(.setCalendarPopups(popups))
                    await send(.setPopupEventCounts(Self.eventCounts(from: popups)))
                    await send(.setSelectedPopups(Self.popups(from: popups, on: state.selectedDate)))
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
                    await send(.setCalendarPopups(popups))
                    await send(.setPopupEventCounts(Self.eventCounts(from: popups)))
                    await send(.setSelectedPopups(Self.popups(from: popups, on: state.selectedDate)))
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
            let currentPopup = state.calendarPopups.first { $0.popupUuid == popup.popupUuid } ?? popup
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
            } catch {
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
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
