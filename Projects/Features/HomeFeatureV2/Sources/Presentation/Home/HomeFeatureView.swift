import SwiftUI
import ComposableArchitecture
import PopPangListKit
import Domain
import DSKit

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var userUuid: String
        public var nickname: String
        public var bestPopups: [Popup] = []
        public var comingPopups: [Popup] = []
        public var gridPopups: [Popup] = []
        
        var filter = HomeFilter.State()
        
        public init(
            user: User,
            bestPopups: [Popup],
            comingPopups: [Popup],
            gridPopups: [Popup]
        ) {
            self.userUuid = user.userUuid
            self.nickname = user.nickname ?? "닉네임"
            self.bestPopups = bestPopups
            self.comingPopups = comingPopups
            self.gridPopups = gridPopups
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case bestPopupTapped(popupUuid: String)
        case comingPopupTapped(popupUuid: String)
        case gridPopupTapped(popupUuid: String)
        
        case filter(HomeFilter.Action)
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            .none
        }
    }
}

public struct HomeFeatureView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
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
                    showsPopupRequestManagement: true,
                    onSearch: { _ in },
                    onAlert: { _ in },
                    onReport: {},
                    onManagePopupRequests: {}
                )
                .padding(.bottom, 16)
                
                // MARK: - List
                PopPangList {
                    
                    // MARK: - Best
                    bestPopupSection(
                        popups: store.bestPopups
                    ) { popupUuid in
                        store.send(.bestPopupTapped(popupUuid: popupUuid))
                    }
                    .withHeader {
                        HomeBestHeader(nickname: store.nickname)
                            .padding(.bottom, 10)
                    }
                    .headerBackground(UIColor(Color.subWhite))
                    
                    // MARK: - Coming
                    comingPopupSection(
                        popups: store.comingPopups
                    ) { popupUuid in
                        store.send(.comingPopupTapped(popupUuid: popupUuid))
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
                    
                    // MARK: - Grid
                    gridPopupSection(popups: store.bestPopups) { popupUuid in
                        store.send(.gridPopupTapped(popupUuid: popupUuid))
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
                }
            }
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
    
    let popups: [Popup] = Array(repeating: .popupMock, count: 20)
    
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
                ),
                bestPopups: popups,
                comingPopups: popups,
                gridPopups: popups
            )
        ) {
            HomeFeature()
        }
    )
}


















// MARK: - BestPopup Section
//@MainActor
//private struct BestPopupSection {
//    let popups: [Popup]
//    let onTap: (String) -> Void
//    
//    var section: PopPangListKit.Section {
//        Section(id: "best") {
//            for popup in popups {
//                Cell(
//                    // setting
//                    id: popup.popupUuid,
//                    item: popup,
//                    layoutMode: .fitContent(
//                        estimatedSize: CGSize(width: 194, height: 271)
//                    )
//                ) { popup in
//                    // conetnt
//                    BestPopupCell(popup: popup)
//                }
//                .didSelect { _ in
//                    onTap(popup.popupUuid)
//                }
//            }
//        }
//        .withSectionLayout(
//            HorizontalLayout(spacing: 8)
//                .insets(
//                    .init(top: 0, leading: 20, bottom: 0, trailing: 20)
//                )
//        )
//    }
//}




/*
 @State private var items = Array(1...20)
public var body: some View {
    PopPangList {
        Section(id: "numbers") {
            
            Cell(
                id: 1,
                item: "hello world"
            ) { value in
                Text("\(value)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.green)
            }
            
            for item in items {
                Cell(
                    id: item,
                    item: item
                ) { value in
                    Text("\(value)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.green)
                }
            }
        }
        .withSectionLayout(.vertical(spacing: 8))
    }
    .background(Color.subWhite)
}
 */
