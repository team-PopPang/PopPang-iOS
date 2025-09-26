//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct BestPopup: Hashable {
    let imageName: String
    let title: String
    let address: String
}

struct HomeView: View {
    private var bestPopups: [BestPopup] = [
        BestPopup(imageName: "img_0",
                      title: "팝마트",
                      address: "서울 성동구"),
        BestPopup(imageName: "img_1",
                      title: "팝마트",
                      address: "서울 영등포구"),
        BestPopup(imageName: "img_2",
                      title: "팝마트",
                      address: "서울 영등포구"),
        BestPopup(imageName: "img_3",
                      title: "팝마트",
                      address: "서울 성동구"),
        BestPopup(imageName: "img_4",
                      title: "팝마트",
                      address: "서울 성동구"),
        BestPopup(imageName: "img_5",
                      title: "팝마트",
                      address: "서울 성동구"),
    ]
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute>
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                text: $searchText)
                .disabled(true)
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            coordinator.push(.search)
                        }
                }
                
                AlertButton {
                    print("알림 버튼 클릭됨")
                    coordinator.push(.alert)
                }
                .padding(.leading, .contentPadding)
                
                
            }
            
            AdHScrollView(bestPopups: bestPopups)
            
            Spacer()
        }
        .padding(.contentPadding)
    }
}

private struct AdHScrollView: View {
    var bestPopups: [BestPopup]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(bestPopups, id: \.self) { popup in
                    ZStack(alignment: .bottomLeading) {
                        Image("\(popup.imageName)")
                            .resizable()
                            .aspectRatio(contentMode: .fill) // 프레임을 채움
                            .frame(width: 194, height: 271)  // 포스트 사이즈
                            .clipped()                       // 넘치는 영역 제거
                        
                        VStack(alignment: .leading) {
                            Text(popup.title)
                                .font(.scdream(.bold, size: 14))
                                .foregroundStyle(Color.bestPostTitle)
                            HStack(spacing: 2) {
                                Image("Address")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                Text(popup.address)
                                    .font(.scdream(.medium, size: 12))
                                    .foregroundStyle(Color.bestPostAddress)
                            }
                        }
                        .padding(11)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

