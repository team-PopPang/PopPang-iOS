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
            VStack {
                HStack {
                    PopupCategoryTag(text: "테스트태그")
                    
                    Spacer()
                    
                    Button {
                        onDismiss()
                        print("눌림")
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(.system(size: 15, weight: .regular))
                    }
                }
                .padding(.top, 20)
                
                HStack {
                    Text(popup.name)
                        .ppStyleFont(.scdream(.bold, size: 18))
                        .foregroundStyle(Color.mainBlack)
                    
                    Spacer()
                }
                .padding(.top, 11)
                
                KFImage(URL(string: popup.imageUrlList[0]))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageWidth, height: 182)
                    .clipped()
                    .allowsHitTesting(false)
                    .padding(.top, 26)
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

