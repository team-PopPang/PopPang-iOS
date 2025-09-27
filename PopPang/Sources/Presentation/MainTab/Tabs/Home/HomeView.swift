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
        VStack(spacing: 0) {
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
            
            // MARK: - Best Popup
            BestPopupScrollView(bestPopups: bestPopups)
                .padding(.top, 10)
            
            // MARK: - Coming Popup
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("COMING SOON")
                        .font(.scdream(.medium, size: 11))
                        .foregroundStyle(Color.mainOrange)
                    
                    Text("곧 생기는 팝업")
                        .font(.scdream(.bold, size: 15))
                }
                Spacer()
                
                Button {
                    
                } label: {
                    Image("navigationBtn")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.top, 20)
            ComingPopupScrollView(comingPopups: bestPopups)
            
            Spacer()
        }
        .padding(.contentPadding)
    }
}

private struct BestPopupScrollView: View {
    var bestPopups: [BestPopup]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(bestPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    BestPopupCell(popup: popup)
                }
            }
        }
    }
}

private struct BestPopupCell: View {
    let popup: BestPopup
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // MARK: - 이미지
            Image("\(popup.imageName)")
                .resizable()
                .aspectRatio(contentMode: .fill) // 프레임을 채움
                .frame(width: 194, height: 271)  // 포스트 사이즈
                .clipped()                       // 넘치는 영역 제거
            
            // MARK: - 그라데이션
            /// startPoint -> endPoint방향으로 색이 변함
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.mainBlack.opacity(0.0), location: 0.0),
                    .init(color: Color.mainBlack.opacity(0.16), location: 0.6),
                    .init(color: Color.mainBlack.opacity(0.56), location: 1.0),
                
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100) // 이미지 하단 100px 영역만 덮음
            .clipped()          // 그라데이션 100px만 보이고 넘는 부분 차단
            
            // 기본 버전
            // .frame(width: 194, height: 271) // 이미지와 동일 크기
            // .clipped()
           
            
            // MARK: - 텍스트 오버레이
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

private struct ComingPopupScrollView: View {
    var comingPopups: [BestPopup]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(comingPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    ComingPopupCell(popup: popup)
                    
                }
            }
            .padding(.vertical, 10)
        }
    }
}

private struct ComingPopupCell: View {
    let popup: BestPopup
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.subWhite)
                .frame(width: 289, height: 114)
                // MARK: - Spread 임시
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.subWhite2, lineWidth: 0.05)
                }
                // MARK: - 그림자 작용
                .applyShadow(color: .subWhite2, alpha: 0.2, x: 0, y: 0, blur: 13)
              
               
            
            HStack(spacing: 0) {
                // MARK: - 이미지
                Image(popup.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 83, height: 104)
                    .clipped()
                    .padding(5)
                
                // MARK: - 설명문구
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("10.05 오픈")
                            .font(.scdream(.medium, size: 11))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 7)
                            .background(Color.mainOrange)
                            .foregroundStyle(Color.subWhite)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image("like")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 15)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("올리브영 9월 팝업스토어 총정리")
                            .font(.scdream(.medium, size: 13))
                        Text("서울 마포구")
                            .font(.scdream(.regular, size: 11))
                    }
                    .padding(.bottom, 15)
                }
                .padding(.leading, 5)
            }
            .frame(width: 289, height: 114)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Coordinator<MainRoute, SheetRoute>())
}

extension View {
    func applyShadow(
        color: Color = .black,
        alpha: Double = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 20,
        blur: CGFloat = 35
    ) -> some View {
        self.shadow(
            color: color.opacity(alpha),
            radius: blur / 2,
            x: x,
            y: y
        )
    }
}
