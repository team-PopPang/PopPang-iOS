//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import NMapsMap
import Kingfisher
import BottomSheet

struct MapView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var mapViewModel: MapViewModel

    // MARK: - 시트 관련
    @State var firstSheetPosition: BottomSheetPosition = .relative(0.5)
    @State var secondSheetPosition: BottomSheetPosition = .hidden
    @State private var sheetTop: CGFloat = 400
    
    // MARK: - 두번쨰 시트 열기 위함
    @State private var secondSheetType: SecondSheetType = .none
    
    // MARK: - 높이
    @State private var mapSearchTextFieldFrame: CGRect = .zero
    @State private var tabBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            NaverMapView(popups: mapViewModel.mapPopups)
                .onAppear {
                    MapCoordinator.shared.checkIfLocationServiceIsEnabled()
                    MapCoordinator.shared.onMarkerSelected = { key, popup in
                        coordinator.push(.popupDetail(mapViewModel.userUuid, popup))
                    }
                }
            
            // MARK: - 지역필터링 & 검색 텍스트필드
            HStack(spacing: 0) {
                
                // MARK: - 지역 필터링 버튼
                MapRegionButton(text: mapViewModel.selectedRegion?.region ?? "전체") {
                    
                    // MARK: - 첫 시트가 닫혀 있다면 열기
                    if firstSheetPosition == .absolute(0) {
                        firstSheetPosition = .relative(0.5)
                    }
                    
                    // MARK: - 두번째 시트 열기
                    secondSheetType = .region
                    secondSheetPosition = firstSheetPosition
                }
                
                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.mainGray8)
                
                // MARK: - 검색 텍스트필드
                MapSearchTextField(placeholder: "궁금한 팝업을 검색해보세요",
                                   text: $mapViewModel.searchText) {
                }
                
            }
            .background {
                GeometryReader { geo in
                    Color.subWhite
                        .cornerRadius(3)
                        .onAppear {
                            DispatchQueue.main.async {
                                mapSearchTextFieldFrame = geo.frame(in: .global)
                                
                                // 시트 위치 1번만 계산해서 저장
                                let top = UIScreen.main.bounds.height - (mapSearchTextFieldFrame.maxY + 20)
                                
                                // 최소값 보정(너비 깨짐 방지)
                                sheetTop = max(top, 200)
                            }
                            // print(mapSearchTextFieldFrame) /// x, y, width, height
                            // print("top(minY): \(Int(mapSearchTextFieldFrame.minY))")
                            // print("bottom(maxY): \(Int(mapSearchTextFieldFrame.maxY))")
                            // print("height: \(Int(mapSearchTextFieldFrame.height))")
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, getSafeArea().top + 10)
            .padding(.horizontal, 15)
            
            // MARK: - 내위치 이동 버튼
            Button {
                // 시트가 없을때 제외하고는 항상 -300
                if firstSheetPosition == .absolute(0)  {
                    MapCoordinator.shared.moveToUserLocation()
                } else {
                    MapCoordinator.shared.moveToUserLocation(yOffset: -300)
                }
            } label: {
                Image("location")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 50)
            
            // MARK: - 목록 보기 버튼
            if case .absolute(0) = firstSheetPosition {
                VStack {
                    Spacer()
                    Button {
                        firstSheetPosition = .relative(0.5)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "list.bullet")
                                // .foregroundStyle(Color.mainOrange)
                                .foregroundStyle(Color.mainBlack)
                                .frame(width: 12, height: 12)
                                .padding(.bottom, 3)
                            
                            Text("목록 보기")
                                .foregroundStyle(Color.mainBlack)
                                .font(.scdream(.regular, size: 12))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.subWhite)
                        .cornerRadius(20)
                    }
                    .applyShadow(color: Color.mainBlack,
                                 alpha: 0.5, x: 0, y: 1, blur: 3)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .padding(.bottom, 20 + tabBarHeight)
            }
        }
        .background(
            // TabBar 높이 추적
            TabBarProxy { _, tabBar in
                let contentHeight = tabBar.bounds.height
                self.tabBarHeight = contentHeight
            }
        )
        .onAppear {
            LocationPermissionManager.shared.requestPermission()
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                await mapViewModel.updatePersonamMapFilteredPopupList()
            }
        }
        // MARK: - 첫 번째 시트
        .bottomSheet(bottomSheetPosition: $firstSheetPosition,
                     
                     // MARK: - 시트의 높이
                     switchablePositions: [.absolute(0),   // 절댓값: 완전 화면에서 안보임(frame이 0)
                                           .relative(0.5), // 상대값: 화면의 절반 차지
                                           // 절댓값: 화면 검색바의 밑면까지의 높이 - 20만큼(frame이 20)
                                           .absoluteTop(sheetTop)
                     ],
                     content: {
            // view
            FirstSheetView(mapViewModel: mapViewModel,
                           firstSheetPosition: $firstSheetPosition,
                           onRegionTap: {
                               secondSheetType = .region
                               secondSheetPosition = firstSheetPosition
                           },
                           onSortTap: {
                               secondSheetType = .sort
                               secondSheetPosition = firstSheetPosition
                           })
        })
        // 가로 전체폭
        .sheetWidth(.relative(1.0))
        
        // 첫 번째 배경
        .customBackground(
            Color.subWhite
                .cornerRadius(30)
        )
        
        // MARK: - 두 번째 시트
        .bottomSheet(bottomSheetPosition: $secondSheetPosition,
                     switchablePositions: [.relative(0.5),
                                           .absoluteTop(sheetTop)],
                     content: {
            // view
            SecondSheeetView(mapViewModel: mapViewModel,
                             type: secondSheetType) {
                // MARK: - SecondSheeetView.onDismiss()
                // 닫기 버튼 누르면 숨기겠다
                secondSheetPosition = .hidden
            }
                             

        })
        // 세로 전체폭
        .sheetWidth(.relative(1.0))
        
        // 두 번째 배경
        .customBackground(
            Color.subWhite
                .cornerRadius(30)
        )
        
        // MARK: - 두 번째 시트 높이 변경 시 첫 시트도 높이 동기화
        .onChange(of: secondSheetPosition) { _, newValue in
            if newValue != .hidden {
                firstSheetPosition = newValue
            }
        }
        
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .bottom)
    }
}

extension MapView {
    func getSafeArea() -> UIEdgeInsets {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return .zero
        }
        
        return window.safeAreaInsets
    }
}

// MARK: - SwiftUI와 UIKit 연결
struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    func makeCoordinator() -> MapCoordinator {
        Coordinator.shared
    }

    func makeUIView(context: Context) -> some UIView {
        context.coordinator.getNaverMapView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // vm에서 spots갱신시마다 Coordinator에 반영
        context.coordinator.updateSpots(popups)
    }
}

#Preview("지도 탭 미리보기") {
    @Previewable @State var selectedTab: MainTabType = .map
    TabView(selection: .constant(MainTabType.map)) {
        MapView()
            .tabItem {
                Image(systemName: "map")
                Text("지도")
            }
            .tag(MainTabType.map)
    }
    .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    .environmentObject(MapViewModel(userUuid: "1234"))
}

