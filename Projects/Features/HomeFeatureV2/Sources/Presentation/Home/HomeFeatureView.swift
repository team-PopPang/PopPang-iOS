import SwiftUI
import ComposableArchitecture
import PopPangListKit
import Domain
import DSKit

@Reducer
public struct HomeFeature {
    @Dependency(\.homePopupClient) private var popupClient: HomePopupClient
    
    @ObservableState
    public struct State: Equatable {
        // self state
        public var userUuid: String
        public var nickname: String
        public var isAdmin: Bool
        
        public var bestPopups: [Popup] = []
        public var comingPopups: [Popup] = []
        public var gridPopups: [Popup] = []
        
        var isLoading = false
        var errorMessage: String?
        
        // child state
        var filter = HomeFilter.State()
        
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
        case errorMessageChanged(String?)
        case popupSectionsLoaded(HomePopupSections)
        case loadingChanged(Bool)
        
        // tap action
        case bestPopupTapped(popupUuid: String)
        case comingPopupTapped(popupUuid: String)
        case gridPopupTapped(popupUuid: String)
        
        // child action
        case filter(HomeFilter.Action)
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
            HomeFilter()
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
                
            case .loadingChanged: return .none
                
            case .bestPopupTapped: return .none
                
            case .comingPopupTapped: return .none
                
            case .gridPopupTapped: return .none
                
            case .filter:
                return .none
                
            }
        }
    }
}

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
        filter: HomeFilter.State
    ) -> Effect<Action> {
        return Effect.run { send in
            // popupClient, userUuid, filter 캡처
            do {
                let regions = filter.regions.isEmpty
                ? try await popupClient.getRegionList().sortedByHomePriority()
                : filter.regions
                
                let selectedRegion = filter.selectedRegion ?? regions.first
                let selectedDistrict = filter.selectedDistrict ?? selectedRegion?.districtList.first
                
                // filter send
                // await send(.filter(.))
                
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















public struct HomeFeatureView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    // PopPangList에 스크롤 이동 명령을 전달하는 View 전용 객체입니다.
    @State private var listProxy = ListProxy()

    public init(
        store: StoreOf<HomeFeature>
    ) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            // MARK: - background
            Color.subWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {

                // MARK: - Navigationbar
                HomeNavigationBar(
                    userUuid: store.userUuid,
                    showsPopupRequestManagement: store.isAdmin,
                    onSearch: { _ in },
                    onAlert: { _ in },
                    onReport: {},
                    onManagePopupRequests: {}
                )
                .padding(.bottom, 16)
                
                // MARK: - List
                PopPangList(proxy: listProxy) {
                    
                    // MARK: - Best
                    bestPopupSection(
                        popups: store.bestPopups
                    ) { popupUuid in
                        store.send(.bestPopupTapped(popupUuid: popupUuid))
                    }
                    
                    // MARK: - Coming
                    comingPopupSection(
                        popups: store.comingPopups
                    ) { popupUuid in
                        store.send(.comingPopupTapped(popupUuid: popupUuid))
                    }
                    
                    // MARK: - Grid
                    gridPopupSection(popups: store.gridPopups) { popupUuid in
                        store.send(.gridPopupTapped(popupUuid: popupUuid))
                    }
                }
                .scrollOverlay(
                    // 화면 높이의 1.5배만큼 스크롤하면 위로 가기 버튼을 표시합니다.
                    alignment: .bottomTrailing,
                    visibleWhen: .relativeToViewport(1.5)
                ) { isVisible in
                    HomeTopAnchorButton(isVisible: isVisible) {
                        listProxy.scrollToSection(
                            id: "grid",
                            position: .top,
                            animated: true
                        )
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - BestPopup Section
extension HomeFeatureView {
    
    private func bestPopupSection(
        popups: [Popup],
        onTap: @escaping (String) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "best") {
            For(popups, id: \.popupUuid) { popup in
                BestPopupCell(popup: popup)
            }
            .didSelect { popup in
                onTap(popup.popupUuid)
            }
            .layoutMode(.fitContent(estimatedSize: BestPopupCell.layoutSize))
        }
        .withHeader {
            HomeBestHeader(nickname: store.nickname)
                .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
        .withSectionLayout(
            HorizontalLayout(
                spacing: 15,
                scrollingBehavior: .continuousGroupLeadingBoundary
            )
            .insets(.init(top: 0, leading: .contentPadding, bottom: 50, trailing: .contentPadding))
            .headerPinToVisibleBounds(true)
        )
    }
}

// MARK: - ComingPopup Section
extension HomeFeatureView {
    private func comingPopupSection(
        popups: [Popup],
        onTap: @escaping (String) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "comming") {
            For(popups, id: \.popupUuid) { popup in
                ComingPopupCell(popup: popup)
            }
            .didSelect { popup in
                onTap(popup.popupUuid)
            }
            .layoutMode(.fitContent(estimatedSize: ComingPopupCell.layoutSize))
        }
        .withHeader {
            HomeComingHeader(
                userUuid: store.userUuid,
                popups: store.comingPopups,
                onTap: { _, _ in
                    
                }
            )
            .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
        .withSectionLayout(
            HorizontalLayout(
                spacing: 15,
                scrollingBehavior: .groupPaging
            )
            .insets(.init(top: 0, leading: .contentPadding, bottom: 65, trailing: .contentPadding))
            .headerPinToVisibleBounds(true)
        )
    }
}

// MARK: - GridPopup Section
extension HomeFeatureView {
    private func gridPopupSection(
        popups: [Popup],
        onTap: @escaping (String) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "grid") {
            For(popups, id: \.popupUuid) { popup in
                GridPopupCell(
                    popup: popup,
                    toggleLike: {
                        onTap(popup.popupUuid)
                    }
                )
            }
            .didSelect { popup in
                onTap(popup.popupUuid)
            }
            .layoutMode(
                .flexibleHeight(
                    estimatedHeight: GridPopupCell.estimatedHeight
                )
            )
        }
        .withHeader {
            HomeFilterHeader(
                store: store.scope(
                    state: \.filter,
                    action: \.filter
                ),
                onRegionTap: {
                    // 지역 바텀시트 열기
                },
                onSortTap: {
                    // 정렬 바텀시트 열기
                }
            )
            .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
        .withSectionLayout(
            VerticalGridLayout(
                numberOfItemsInRow: 2,
                itemSpacing: 15,
                lineSpacing: 20
            )
            .insets(
                .init(
                    top: 0,
                    leading: .contentPadding,
                    bottom: 0,
                    trailing: .contentPadding
                )
            )
            .headerPinToVisibleBounds(true)
        )
    }
}

#Preview {
    HomeFeatureView(
        store: Store(
            initialState: HomeFeature.State(
                user: User(
                    userUuid: "preview-user",
                    uid: "preview-uid",
                    provider: "preview",
                    email: nil,
                    nickname: "홍길동",
                    role: "USER",
                    isAlerted: false,
                    fcmToken: nil,
                    alertKeywordList: nil,
                    recommendList: nil
                )
            )
        ) {
            HomeFeature()
        }
    )
}
