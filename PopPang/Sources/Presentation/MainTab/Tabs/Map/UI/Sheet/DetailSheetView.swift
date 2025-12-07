//
//  DetailSheetView.swift
//  PopPang
//
//  Created by 김동현 on 11/25/25.
//

import SwiftUI
import Kingfisher

struct DetailSheetView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var mapViewModel: MapViewModel
    let popup: Popup
    let onDismiss: () -> Void
    let imageWidth: CGFloat = UIScreen.main.bounds.width - 30
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                
                // MARK: - Header
                HStack(alignment: .firstTextBaseline) {
                    
                    Text(popup.recommendList[0])
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainGray9)
                    
                    Spacer()
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(.system(size: 11, weight: .regular))
                            .frame(width: 27, height: 27)
                            .background(Color.mainGray5)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 10)
                
                // MARK: - Title
                HStack(spacing: 0) {
                    Text(popup.name)
                        .ppStyleFont(.scdream(.bold, size: 18))
                        .foregroundStyle(Color.mainBlack)
                    
                    Spacer()
                }
                
                // MARK: - Body
                VStack(spacing: 5) {
                    HStack(spacing: 0) {
                        Text("운영 장소")
                            .ppStyleFont(.scdream(.light, size: 12))
                            .foregroundStyle(Color.mainGray)
                        
                        Text(popup.roadAddress)
                            .ppStyleFont(.scdream(.regular, size: 12))
                            .foregroundStyle(Color.mainBlack)
                            .padding(.leading, 5)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 5) {
                        Text("운영 날짜")
                            .ppStyleFont(.scdream(.light, size: 12))
                            .foregroundStyle(Color.mainGray)
                        
                        HStack(spacing: 3) { 
                            Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                            Text("-")
                            Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                        }
                        .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                        .foregroundStyle(Color.mainBlack)
                        
                        Spacer()
                    }
                    HStack(spacing: 5) {
                        if let _ = popup.openTime, let _ = popup.closeTime {
                            Text("운영 시간")
                                .ppStyleFont(.scdream(.light, size: 12))
                                .foregroundStyle(Color.mainGray)
                        }
                        
                        HStack(spacing: 2) {
                            if let openTime = popup.openTime, let closeTime = popup.closeTime {
                                Text(openTime)
                                Text("-")
                                Text(closeTime)
                            }
                        }
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                        
                        Spacer()
                    }
                }
                .padding(.top, 10)
                
                KFImage(URL(string: popup.imageUrlList[0]))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageWidth, height: 182)
                    .clipped()
                    .allowsHitTesting(false)
                    .padding(.top, 20)
            }
            .padding(.horizontal, .contentPadding)
        }
        .onTapGesture {
            coordinator.push(.popupDetail(mapViewModel.userUuid, popup))
        }
    }
}

#Preview {
    DetailSheetView(popup: .popupMock) {
        
    }
    .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
    .environmentObject(MapViewModel(userUuid: "1234"))
}


// MARK: - 텍스트 렌더링 높이 측정용
struct SizeReader: ViewModifier {
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { size = geo.size }
                        .onChange(of: geo.size) { _, newValue in
                            size = newValue
                        }
                }
            )
    }
}

extension View {
    func readSize(_ size: Binding<CGSize>) -> some View {
        self.modifier(SizeReader(size: size))
    }
}

