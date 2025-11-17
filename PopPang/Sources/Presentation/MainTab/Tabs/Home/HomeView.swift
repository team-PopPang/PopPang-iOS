//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @State private var searchText = ""
    
    // MARK: - 딥링크 관련
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastHandledPopupId: String?
    
    // MARK: - 광고뷰 테스트
    @State private var hasSeenPopup: Bool = false
    
    // MARK: - 스크롤 버튼
    @State private var startScrollOffset: CGFloat = 0
    @State private var currentScrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // MARK: - Search & Alert
                CustomNavigationBar {
                    
                    Text("POP PANG")
                        .ppStyleFont(.scdream(.black, size: 20))
                        .foregroundStyle(Color.mainOrange)
                    
                    Spacer()
                    
                    IconButton(image: "SearchDark", imageSize: 25) {
                        coordinator.presentSheet(.search(uuid: rootViewModel.user?.userUuid ?? ""))
                    }
                    
                    IconButton {
                        coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                    }
                }
                .padding(.bottom, 15)
                
                ScrollViewReader { proxyHeader in
                    
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text("\(rootViewModel.user?.nickname ?? "닉네임")")
                                        .foregroundStyle(Color.mainOrange)
                                        .font(.scdream(.bold, size: 15))
                                    
                                    Text("님을 위한 팝업")
                                        .font(.scdream(.bold, size: 15))
                                        .foregroundStyle(Color.mainBlack)
                                }
                                
                                // MARK: - Best Popup
                                BestPopupScrollView(homeViewModel: homeViewModel)
                                    .padding(.top, 15)
                            }
                            
                            // MARK: - Coming Popup
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("COMING SOON")
                                        .font(.scdream(.medium, size: 11))
                                        .foregroundStyle(Color.mainOrange)
                                    
                                    Text("오픈 예정 팝업")
                                        .font(.scdream(.bold, size: 15))
                                        .foregroundStyle(Color.mainBlack)
                                }
                                Spacer()
                                
                                Button {
                                    coordinator.push(.comingPopupDetail)
                                } label: {
                                    Image("navigationButton")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                }
                                .padding(.trailing, .contentPadding)
                            }
                            .padding(.top, 50)
                            
                            ComingPopupScrollView(homeViewModel: homeViewModel)
                            
                            // MARK: - DropDownView
                            HStack {
                                Text(homeViewModel.selectedRegion?.region ?? "전체")
                                    .foregroundStyle(Color.mainBlack)
                                    .ppStyleFont(.scdream(.medium, size: 17))
                                
                                if let selectedDistrict = homeViewModel.selectedDistrict,
                                   selectedDistrict != "전체" {
                                    Text(selectedDistrict)
                                        .foregroundStyle(Color.mainBlack)
                                        .ppStyleFont(.scdream(.medium, size: 17))
                                }
                                
                                Spacer()
                                
                                RegionButton(text: "지역") {
                                    homeViewModel.showRegionSheet.toggle()
                                }
                                .padding(.leading, -10)
                                
                                SortButton(selectedOption: $homeViewModel.selectedOption) {
                                    homeViewModel.showSortSheet.toggle()
                                }
                            }
                            .padding(.top, 50)
                            .padding(.trailing, .contentPadding)
                            // 스크롤 최상단 목적지
                            .id("Scroll_To_Top")
                            
                            // MARK: - GridView
                            GridPopupScrollView(homeViewModel: homeViewModel)
                                .padding(.top, 15)
                                .padding(.trailing, .contentPadding)
                               
                        }
                        .padding(.bottom, 50)
                        
//                        // 스크롤 최상단 목적지
//                        .id("Scroll_To_Top")
                        
                        // offset 구하기
                        .overlay(
                            GeometryReader { proxy -> Color in
                                DispatchQueue.main.async {
                                    if startScrollOffset == 0 {
                                        self.startScrollOffset = proxy.frame(in: .named("scroll")).minY
                                    }
                                    let offset = proxy.frame(in: .named("scroll")).minY
                                    self.currentScrollOffset = offset - startScrollOffset
                                }
                                return Color.clear
                            }
                            .frame(width: 0, height: 0)
                            ,alignment: .top
                        )
                    }
                    .padding(.leading, .contentPadding)
                    
                    // 스크롤 전용 좌표계
                    .coordinateSpace(name: "scroll")
                    
                    // 특정 offset일때 버튼 보이게 하자
                    .overlay(
                        Button {
                            withAnimation(.default) {
                                proxyHeader.scrollTo("Scroll_To_Top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20) /// 안전영역이 없는 기종은 12px 더주고, 홈인디케이터가 있는 기종은 패딩을 안주겠다
                        // startOffset이 450보다 작으면 투명도 적용
                        .opacity(currentScrollOffset < -650 ? 1 : 0)
                        
                        // 우측 하단 버튼 고정
                        ,alignment: .bottomTrailing
                    )
                }
            }
        }
        .onAppear {
            
            Task {
                await homeViewModel.getAllPopupData()
            }
            
            if !hasSeenPopup {
                /*
                coordinator.presentOverlay(overlay: .notice(title: "베타 업데이트 내용",
                                                            content: Constants.BetaNotice.beta_1012))
                 */

                hasSeenPopup = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    handleDeeplinkIfNeeded()
                }
            }
        }
        .fullScreenCover(item: $coordinator.sheet) { route in
            coordinator.buildView(for: route)
        }
        .withoutAnimation()
        .sheet(isPresented: $homeViewModel.showRegionSheet, onDismiss: {
            if let region = homeViewModel.selectedRegion {
                Logger.d("선책된 지역: \(region.region)")
            }
            Logger.d("선택된 정렬: \(homeViewModel.selectedOption.rawValue)")
            
            Task {
                await homeViewModel.updatePersonalFilteredPopupList()
            }
        }) {
            RegionButtonSheet(regions: homeViewModel.regions,
                        selectedRegion: $homeViewModel.selectedRegion,
                        selectedDistrict: $homeViewModel.selectedDistrict)
            .presentationDetents([.fraction(0.8)])
        }
        .sheet(isPresented: $homeViewModel.showSortSheet, onDismiss: {
            if let region = homeViewModel.selectedRegion {
                Logger.d("선책된 지역: \(region.region)")
            }
            Logger.d("선택된 정렬: \(homeViewModel.selectedOption.rawValue)")
            Task {
                await homeViewModel.updatePersonalFilteredPopupList()
            }
        }) {
            SortButtonSheet(selectedOption: $homeViewModel.selectedOption)
                .presentationDetents([.fraction(0.4)])
        }
    }
}

// MARK: - 딥링크 관련
extension HomeView {
    // MARK: - 딥링크 감지
    private func handleDeeplinkIfNeeded() {
        Task {
            guard let popupId = UserDefaultsManager.loadDeeplinkPopupId() else { return }
            Logger.d("딥링크 감지됨 — \(popupId)")

            // ✅ 데이터가 로드될 때까지 대기
            while homeViewModel.bestPopups.isEmpty &&
                  homeViewModel.comingPopups.isEmpty &&
                  homeViewModel.gridPopups.isEmpty {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초씩 반복 확인
                Logger.d("팝업 데이터 로드 대기 중...")
            }

            // 데이터가 준비되면 이동
            await MainActor.run {
                moveToPopupDetailIfExists(popupId: popupId)
                UserDefaultsManager.removeDeeplinkPopupId()
            }
        }
    }
    
    // MARK: - 딥링크 화면 이동
    private func moveToPopupDetailIfExists(popupId: String) {
        let allPopups = homeViewModel.bestPopups + homeViewModel.comingPopups + homeViewModel.gridPopups

        if let targetPopup = allPopups.first(where: { $0.popupUuid == popupId }) {
            coordinator.push(.popupDetail(homeViewModel.userUuid, targetPopup))
            Logger.d("팝업 상세로 이동 — \(targetPopup.name)")
        } else {
            Logger.w("해당 popupId에 맞는 팝업을 찾을 수 없음")
        }
    }
}

// MARK: - Best Popup
private struct BestPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var homeViewModel: HomeViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(homeViewModel.bestPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    BestPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(homeViewModel.userUuid, popup))
                        }
                }
            }
            .padding(.trailing, .contentPadding)
        }
    }
}

// MARK: - Coming Popup
private struct ComingPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var homeViewModel: HomeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(homeViewModel.comingPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    ComingPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(homeViewModel.userUuid, popup))
                        }
                }
            }
            .padding(.vertical, 15)
            .padding(.trailing, .contentPadding)
        }
    }
}

// MARK: - Current Popup
private struct GridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var homeViewModel: HomeViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(homeViewModel.gridPopups) { popup in
                
                VStack(alignment: .leading) {
                    GridPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(homeViewModel.userUuid, popup))
                        }
                        .padding(.bottom, 0)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(RootViewModel())
        .environmentObject(HomeViewModel(userUuid: "1234"))
}
