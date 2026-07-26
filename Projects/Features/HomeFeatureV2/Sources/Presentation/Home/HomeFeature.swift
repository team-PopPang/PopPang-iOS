import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct HomeFeature {
    @Dependency(\.homePopupClient) private var popupClient: HomePopupClient
    
    @ObservableState
    public struct State: Equatable {
        // self state
        public var userUuid: String
        public var nickname: String
        public var isAdmin: Bool
        
        var bestPopups: [Popup] = []
        var comingPopups: [Popup] = []
        var gridPopups: [Popup] = []
        
        var isLoading = false
        var errorMessage: String?
        
        // child state
        var filter = HomeFilterFeature.State()
        
        public init(
            user: User
        ) {
            self.userUuid = user.userUuid
            self.nickname = user.nickname ?? "닉네임"
            self.isAdmin = user.role.uppercased() == "ADMIN"
        }
    }

    public enum Action: Equatable {
        // self action
        case onAppear
        case nicknameUpdated(String)
        case errorMessageChanged(String?)
        case popupSectionsLoaded(HomePopupSections)
        case loadingChanged(Bool)
        case refreshFilteredPopupList
        case filteredGridPopupList([Popup])
        
        // toggle
        case favoriteToggleTapped(popupUuid: String)
        case favoriteUpdateResponse(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        
        // child action
        case filter(HomeFilterFeature.Action)
        
        // navigation action
        case popupSelected(Popup)
        case alertTapped
        case searchTapped
        case comingPopupsTapped([Popup])
        case popupRequestTapped
        case popupRequestManagementTapped
        
        // delegate
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case popupSelected(Popup)
            case alertTapped
            case searchTapped
            case comingPopupsTapped([Popup])
            case popupRequestTapped
            case popupRequestManagementTapped
        }
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        /**
         공통
         - 둘 다 부모와 자식 Reducer를 연결하고 실행시키는 도구
         
         Scope
         - 부모의 자식 State와 자식 Action을 연결하고, 자식 Reducer를 항상 실행 가능한 상태로 구성
         
         .ifLet
         - 부모의 Optional 자식 State와 자식 Action을 연결하고, 자식 State가 있을 때만 자식 Reducer를 실행 가능한 상태로 구성
         */
        Scope(state: \.filter, action: \.filter) {
            HomeFilterFeature()
        }
        
        Reduce { state, action in
            
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadAllPopupData(
                    userUuid: state.userUuid,
                    filter: state.filter
                )
                
            case .nicknameUpdated(let nickname):
                state.nickname = nickname
                return .none
                
            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none
                
            case .popupSectionsLoaded(let sections):
                state.bestPopups = sections.bestPopups
                state.comingPopups = sections
                    .comingPopups
                    .sorted { $0.startDate < $1.startDate }
                state.gridPopups = sections.gridPopups
                state.errorMessage = nil
                return .none
                
            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none
                
            case .refreshFilteredPopupList:
                state.isLoading = true
                return updatePersonalFilteredPopupList(
                    userUuid: state.userUuid,
                    filter: state.filter
                )
                
            case .filteredGridPopupList(let popups):
                state.gridPopups = popups
                state.errorMessage = nil
                return .none
                
            case .popupSelected(let popup):
                print("선택된 팝업(Delegate): \(popup)")
                return .send(.delegate(.popupSelected(popup)))
                
            case .alertTapped:
                return .send(.delegate(.alertTapped))
                
            case .searchTapped:
                return .send(.delegate(.searchTapped))
                
            case .comingPopupsTapped(let popup):
                return .send(.delegate(.comingPopupsTapped(popup)))
                
            case .popupRequestTapped:
                return .send(.delegate(.popupRequestTapped))
                
            case .popupRequestManagementTapped:
                return .send(.delegate(.popupRequestManagementTapped))
                
            case .favoriteToggleTapped(let popupUuid):
                
                guard let popup = currentPopup(
                    in: state,
                    popupUuid: popupUuid
                ) else {
                    return .none
                }
                
                return requestFavoriteToggle(
                    userUuid: state.userUuid,
                    popup: popup
                )
                
            case .favoriteUpdateResponse(let popupUuid, let isFavorited, let favoriteCount):
                state.bestPopups.applyFavoriteUpdate(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )

                state.comingPopups.applyFavoriteUpdate(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )

                state.gridPopups.applyFavoriteUpdate(
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                
                return .none
                
            case .filter:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - 현재 팝업 찾는 함수
extension HomeFeature {
    private func currentPopup(
        in state: State,
        popupUuid: String
    ) -> Popup? {
        state.gridPopups.first {
            $0.popupUuid == popupUuid
        }
        ?? state.comingPopups.first {
            $0.popupUuid == popupUuid
        }
        ?? state.bestPopups.first {
            $0.popupUuid == popupUuid
        }
    }
}

// MARK: - 전체 팝업 로딩
extension HomeFeature {
    /**
     let popupClient = self.popupClient
     return .run { [popupClient] send in
         try await popupClient.getRegionList()
     }
     - .run은 현재 함수가 끝난 뒤에도 실행될 수 있는 escaping 비동기 클로저다
     - 지역 변수로 먼저 꺼내면 클로저는 HomeFeature 전체인 self가 아닌 필요한 popupClient만 캡처한다
     
     */
    private func loadAllPopupData(
        userUuid: String,
        filter: HomeFilterFeature.State
    ) -> Effect<Action> {
        let popupClient = self.popupClient
        return Effect.run { send in
            // popupClient, userUuid, filter 캡처
            do {
                
                /// 1. 서버에서 지역 목록을 가져온다
                let regions = filter.regions.isEmpty
                ? try await popupClient.getRegionList().sortedByHomePriority()
                : filter.regions
                
                /// 2. 선택된 지역을 결정한다
                let selectedRegion = filter.selectedRegion ?? regions.first
                
                /// 3. 선택된 상세 지역을 결정한다
                let selectedDistrict = filter.selectedDistrict ?? selectedRegion?.districtList.first
                
                /**
                 4. 계산한 값을 자식 Reducer에 전달한다
                 effect.run 내에서는 inout state에 접근할 수 없어서 reduce클로저의 state는 동기적으로 액션을 처리하는 동안만 사용가능하다.
                 run은 비동기 작업이라 reducer실행이 끝난 뒤에도 계속 실행될 수 있다.
                 대신 비동기 작업에서 결과를 계산한 다음 액션으로 보내야 한다.
                 */
                await send(.filter(.regionSelectionPrepared(HomeRegionSelection(
                    regions: regions,
                    selectedRegion: selectedRegion,
                    selectedDistrict: selectedDistrict
                ))))
                
                async let bestPopups = popupClient.getPersonalRandomPopupList(userUuid)
                async let comingPopups = popupClient.getPersonalUpcomingPopupList(userUuid)
                async let gridPopups = popupClient.getPersonalFilteredPopupList(
                    userUuid,
                    selectedRegion?.region ?? "전체",
                    selectedDistrict ?? "전체",
                    filter.selectedOption.rawValue
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
}

// MARK: - 필터링된 팝업 로딩
extension HomeFeature {
    private func updatePersonalFilteredPopupList(
        userUuid: String,
        filter: HomeFilterFeature.State
    ) -> Effect<Action> {
        let popupClient = self.popupClient
        return .run { send in
            do {
                let popups = try await popupClient.getPersonalFilteredPopupList(
                    userUuid,
                    filter.selectedRegion?.region ?? "전체",
                    filter.selectedDistrict ?? "전체",
                    filter.selectedOption.rawValue
                )
                
                await send(.filteredGridPopupList(popups))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
            
            await send(.loadingChanged(false))
        }
    }
}

// MARK: - 배열 팝업 좋아요 갱신
extension Array where Element == Popup {
    mutating func applyFavoriteUpdate(
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        guard let index = firstIndex(
            where: { $0.popupUuid == popupUuid }
        ) else { return }
        
        self[index].isFavorited = isFavorited
        self[index].favoriteCount = favoriteCount
    }
}

// MARK: - 서버 팝업 좋아요 업데이트 요청
extension HomeFeature {
    private func requestFavoriteToggle(
        userUuid: String,
        popup: Popup
    ) -> Effect<Action> {
        .run { send in
            do {
                if popup.isFavorited {
                    try await popupClient.removeFavorite(
                        userUuid,
                        popup.popupUuid
                    )
                } else {
                    try await popupClient.addFavorite(
                        userUuid,
                        popup.popupUuid
                    )
                }
                
                let nextIsFavorited = !popup.isFavorited
                let nextFavoriteCount = nextIsFavorited
                ? popup.favoriteCount + 1
                : max(0, popup.favoriteCount - 1)
                
                await send(
                    .favoriteUpdateResponse(
                        popupUuid: popup.popupUuid,
                        isFavorited: nextIsFavorited,
                        favoriteCount: nextFavoriteCount
                    )
                )
                
            } catch {
                await send(
                    .errorMessageChanged(error.localizedDescription)
                )
            }
        }
    }
}

extension [RegionList] {
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

public struct HomePopupSections: Equatable, Sendable {
    var bestPopups: [Popup]
    var comingPopups: [Popup]
    var gridPopups: [Popup]

    public init(
        bestPopups: [Popup],
        comingPopups: [Popup],
        gridPopups: [Popup]
    ) {
        self.bestPopups = bestPopups
        self.comingPopups = comingPopups
        self.gridPopups = gridPopups
    }
}
