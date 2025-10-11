//
//  AlertView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    private let segments = ["활동", "키워드 설정"]
    
    var body: some View {
        VStack(spacing: 0) {

            // ✅ 세그먼트 헤더
            SegmentedControlView(segments: segments,
                                 views: [AView(),
                                         BView()],
                                 background: .mainGray3,
                                 foreground: .mainOrange,
                                 font: .scdream(.medium, size: 12))
        }
        // toolbar
        .toolbar {
            // 커스텀 타이틀
            ToolbarItem(placement: .principal) {
                Text("알림")
                    .ppStyleFont(.scdream(.medium, size: 20))
                    .padding(.top, 10)
            }
            
            // 커스텀 우측
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image("gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertView()
            .environmentObject(HomeViewModel())
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

struct AView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var homeViewModel: HomeViewModel
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(homeViewModel.gridPopups.enumerated()), id: \.element) { index, popup in
                    AlertPopupCell(popup: popup)
                        .contentShape(Rectangle()) // 터치 영역을 셀 전체로 확장
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                    
                    // 마지막 셀 아래에는 Divider 넣지 않겠다
                    if index != homeViewModel.gridPopups.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .background(Color.subWhite)
                    }
                }
            }
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct AlertPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image("\(popup.imageURL)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.address.shortAddress)
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .ppStyleFont(.scdream(.medium, size: 15))
                        .foregroundStyle(Color.mainBlack)
                    
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .ppStyleFont(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        // .background(.blue)
        .padding(.vertical, 15)
    }
}

struct BView: View {
    @State private var text: String = ""
    @State private var categories = [
        "애니메이션", "캐릭터", "화장품", "패션",
        "식음료"
    ]
    @State private var keywords: [String] = []
    var body: some View {
        VStack {
            
            HStack(spacing: .contentPadding) {
                RoundedTextField(placeholder: "알림 받고 싶은 키워드를 입력해주세요",
                                 text: $text)
                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    // 배열에 같은 값이 없다면 추가
                    if !keywords.contains(trimmed) {
                        keywords.append(trimmed)
                    }
                    
                    // 입력창 초기화
                    text = ""
                    
                    
                } label: {
                    Image("plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            }
            
            ForEach(Array(keywords.enumerated()), id: \.1 ) { index, keyword in
                HStack {
                    Text(keyword)
                        .ppStyleFont(.scdream(.medium, size: 12))
                    Spacer()
                    Button {
                        keywords.remove(at: index)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mainGray)
                    }
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("홍길동")
                        .foregroundStyle(Color.mainOrange)
                        .font(.scdream(.bold, size: 12))
                    Text("님의 최근 본 검색어예요")
                        .font(.scdream(.regular, size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // 선택 버튼들
                SearchFlowLayout(data: categories, id: \.self) { category in
                    SearchFlowButton(title: category) {
                        self.text = category
                    } onRemove: {
                        if let index = categories.firstIndex(of: category) {
                            categories.remove(at: index)
                        }
                    }
                }
                .padding(.top, 15)
            }
            .padding(.top, 30)
            
            
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, .contentPadding)
    }
}

#Preview {
    BView()
}
//
//Button {
//    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//    guard !trimmed.isEmpty else { return }
//    
//    if keywordSet.contains(trimmed) {
//        showDuplicateWarning = true
//        return
//    }
//    keywords.append(trimmed)
//    keywordSet.insert(trimmed)
//    showDuplicateWarning = false
//    text = ""
//} label: {
//    Text("등록")
//        .font(.scdream(.medium, size: 12))
//        .frame(width: 70)
//        .frame(height: 48)
//        .foregroundStyle(Color.mainWhite)
//        .background(Color.mainOrange)
//        .cornerRadius(5)
//}.buttonStyle(PressableButtonStyle())
