import ComposableArchitecture
import Domain
import DSKit
import Foundation

/// 지역 선택과 관련된 값을 한 번에 묶어 전달하는 구조체
public struct HomeRegionSelection: Equatable, Sendable {
    var regions: [RegionList]
    var selectedRegion: RegionList?
    var selectedDistrict: String?

    public init(
        regions: [RegionList],
        selectedRegion: RegionList?,
        selectedDistrict: String?
    ) {
        self.regions = regions
        self.selectedRegion = selectedRegion
        self.selectedDistrict = selectedDistrict
    }
}

@Reducer
public struct HomeFilterFeature {
    
    /// 필터 화면의 상태 저장
    @ObservableState
    public struct State: Equatable {
        var regions: [RegionList] = []
        var selectedRegion: RegionList?
        var selectedDistrict: String?
        var selectedOption: SortButton.SortOption = .newest
        public init() {}
    }
    
    public enum Action: Equatable {
        /// 지역 선택(서울, 부산)
        case regionSelected(RegionList)
        
        /// 상세 지역 선택(강남구, 해운대구)
        case districtSelected(String)
        
        /// 정렬 옵션 선택
        case sortOptionSelected(SortButton.SortOption)
        
        /// 서버에서 지역 초기 데이터 준비
        case regionSelectionPrepared(HomeRegionSelection)
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .regionSelected(let region):
                state.selectedRegion = region
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
