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
    @StateObject private var mapViewModel = MapViewModel()
    @State private var text = ""
    
    // MARK: - 시트 관련
    @State var firstSheetPosition: BottomSheetPosition = .relative(0.5)
    @State var secondSheetPosition: BottomSheetPosition = .hidden
    
    // MARK: - 지역 필터링 선택
    @State private var selectedOption: SortButton.SortOption = .favorite
    
    // MARK: - 높이
    @State private var mapSearchTextFieldFrame: CGRect = .zero
    @State private var tabBarHeight: CGFloat = 0
    
    // MARK: - 테스트
    @State private var secondSheetType: SecondSheetType = .none

    
    var body: some View {
        ZStack(alignment: .trailing) {
            NaverMapView(popups: mapViewModel.mapPopups)
                .onAppear {
                    MapCoordinator.shared.checkIfLocationServiceIsEnabled()
                    MapCoordinator.shared.onMarkerSelected = { key, popup in
                        coordinator.push(.popupDetail(popup))
                    }
                }
            
            MapSearchTextField(placeholder: "궁금한 팝업을 검색해보세요",
                               text: $text)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            mapSearchTextFieldFrame = geo.frame(in: .global)
                            // print(mapSearchTextFieldFrame) /// x, y, width, height
                            // print("top(minY): \(Int(mapSearchTextFieldFrame.minY))")
                            // print("bottom(maxY): \(Int(mapSearchTextFieldFrame.maxY))")
                            // print("height: \(Int(mapSearchTextFieldFrame.height))")
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 70)
            .padding(.horizontal, 15)
            
            // MARK: - 내위치 이동 버튼
            Button {
                MapCoordinator.shared.moveToUserLocation()
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
                                .foregroundStyle(Color.mainOrange)
                                .frame(width: 12, height: 12)
                                .padding(.bottom, 3)
                            
                            Text("목록 보기")
                                .foregroundStyle(Color.mainBlack)
                                .font(.scdream(.light, size: 17))
                                
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(Color.subWhite)
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .padding(.bottom, 20 + tabBarHeight)
                .onAppear {
                    print("목록 보기 열림")
                }
            }
        }
        // TabBar 높이 추적
        .background(
            TabBarProxy { _, tabBar in
                let contentHeight = tabBar.bounds.height
                self.tabBarHeight = contentHeight
            }
        )
        .onAppear {
            LocationPermissionManager.shared.requestPermission()

        }
        // MARK: - 첫 번째 시트
        .bottomSheet(bottomSheetPosition: $firstSheetPosition,
                     
                     // MARK: - 시트의 높이
                     switchablePositions: [.absolute(0),   // 절댓값: 완전 화면에서 안보임(frame이 0)
                                           .relative(0.5), // 상대값: 화면의 절반 차지
                                           // 절댓값: 화면 검색바의 밑면까지의 높이 - 20만큼(frame이 20)
                                           .absoluteTop(UIScreen.main.bounds.height - (mapSearchTextFieldFrame.maxY + 20))
                     ],
                     content: {
            // view
            FirstSheetView(mapViewModel: mapViewModel,
                           onRegionTap: {
                               secondSheetType = .region
                               secondSheetPosition = firstSheetPosition
                           },
                           onSortTap: {
                               secondSheetType = .sort
                               secondSheetPosition = firstSheetPosition
                           })
        })
        // 첫 번째 배경
        .customBackground(
            Color.subWhite
                .cornerRadius(30)
        )
        
        // MARK: - 두 번째 시트
        .bottomSheet(bottomSheetPosition: $secondSheetPosition,
                     switchablePositions: [.relativeTop(0.45), .relativeTop(1.0)],
                     content: {
            // view
            SecondSheeetView(mapViewModel: mapViewModel,
                             type: secondSheetType) {
                // MARK: - SecondSheeetView.onDismiss()
                // 닫기 버튼 누르면 숨기겠다
                secondSheetPosition = .hidden
            }
        })
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
}
