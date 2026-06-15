import ComposableArchitecture
import Domain
import DSKit
import Foundation

@Reducer
struct HomeFilterReducer {
    @ObservableState
    struct State: Equatable, Sendable {
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: SortButton.SortOption = .newest
    }

    enum Action: Equatable, Sendable {
        case regionSelected(RegionList)
        case districtSelected(String)
        case sortOptionSelected(SortButton.SortOption)
        case regionSelectionPrepared(HomeRegionSelection)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .regionSelected(let region):
                state.selectedRegion = region
                state.selectedDistrict = region.districtList.first
                return .none

            case .districtSelected(let district):
                state.selectedDistrict = district
                return .none

            case .sortOptionSelected(let option):
                state.selectedOption = option
                return .none

            case .regionSelectionPrepared(let selection):
                state.regions = selection.regions
                state.selectedRegion = selection.selectedRegion
                state.selectedDistrict = selection.selectedDistrict
                return .none
            }
        }
    }
}
