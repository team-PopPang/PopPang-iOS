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
    
    // MARK: - 광고뷰 테스트
    @State private var hasSeenPopup: Bool = false
    
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
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // MARK: - Best Popup
                        BestPopupScrollView(viewModel: homeViewModel)
                        
                        // MARK: - Coming Popup
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("COMING SOON")
                                    .font(.scdream(.medium, size: 11))
                                    .foregroundStyle(Color.mainOrange)
                                
                                Text("곧 생기는 팝업")
                                    .font(.scdream(.bold, size: 15))
                                    .foregroundStyle(Color.mainBlack)
                            }
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image("navigationButton")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.trailing, .contentPadding)
                        }
                        .padding(.top, 50)
                        ComingPopupScrollView(viewModel: homeViewModel)
                        
                        // MARK: - DropDownView
                        HStack {
                            
                            Text(homeViewModel.selectedRegion?.region ?? "전체")
                                .foregroundStyle(Color.mainBlack)
                                .ppStyleFont(.scdream(.medium, size: 17))
                            
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
                        
                        // MARK: - GridView
                        GridPopupScrollView(viewModel: homeViewModel)
                        .padding(.top, 15)
                        .padding(.trailing, .contentPadding)
                    }
                    .padding(.bottom, 50)
                }
                .padding(.leading, .contentPadding)
            }
        }
        .onAppear {
            
//            print("열림")
//            Task {
//                await homeViewModel.getAllPopupData()
//            }
            
            if !hasSeenPopup {
                /*
                coordinator.presentOverlay(overlay: .notice(title: "베타 업데이트 내용",
                                                            content: Constants.BetaNotice.beta_1012))
                 */

                hasSeenPopup = true
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
        }) {
            RegionSheet(regions: homeViewModel.regions,
                        selectedRegion: $homeViewModel.selectedRegion,
                        selectedDistrict: $homeViewModel.selectedDistrict)
            .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $homeViewModel.showSortSheet, onDismiss: {
            if let region = homeViewModel.selectedRegion {
                Logger.d("선책된 지역: \(region.region)")
            }
            Logger.d("선택된 정렬: \(homeViewModel.selectedOption.rawValue)")
        }) {
            RegionButtonSheet(selectedOption: $homeViewModel.selectedOption)
                .presentationDetents([.fraction(0.4)])
        }
    }
}

// MARK: - Best Popup
private struct BestPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(viewModel.bestPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    BestPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
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
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(viewModel.comingPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    ComingPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                }
            }
            .padding(.vertical, 15)
            .padding(.trailing, .contentPadding)
        }
        //.background(Color.blue)
    }
}

// MARK: - Current Popup
private struct GridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.gridPopups) { popup in
                
                VStack(alignment: .leading) {
                    GridPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
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
        .environmentObject(HomeViewModel(userUuid: "1234"))
}
