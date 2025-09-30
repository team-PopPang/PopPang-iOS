//
//  SearchView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    @State private var selectedCategories: Set<String> = []
    private let categories = [
        "애니메이션", "캐릭터", "화장품", "패션",
        "식음료"
    ]
    
    /// 카테고리 추가/삭제
    /// - Parameter category: 카테고리 타이틀
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Alert
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Image("navigationBtn")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(Color.mainBlack)
                }.padding(.trailing, 10)
                
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                text: $searchText)
                .focused($isFocused)
          
                IconButton {
                    print("알림 버튼 클릭됨")
                    coordinator.presentOverlay(overlay: .notice(title: "공지사항",
                                                                content: "키워드 화면 구현 예정입니다."))
                }
                .padding(.leading, .contentPadding)
            }
            .padding(.top, .contentPadding)
            .padding(.horizontal, .contentPadding)
            .padding(.bottom, 10)
            
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
                FlowLayout(categories, id: \.self) { category in
                                CategoryButton(
                                    title: category,
                                    isSelected: selectedCategories.contains(category)
                                ) {
                                    toggleCategory(category)
                                }
                            }
                .padding(.top, 15)
                
                
            }
            .padding(.contentPadding)
            
            Spacer()
        }
        .onAppear {
            
            Task { @MainActor in
                isFocused = true
            }
            /*
            DispatchQueue.main.async {
                isFocused = true
            }
             */
        }
    }
}

#Preview {
    SearchView()
}
