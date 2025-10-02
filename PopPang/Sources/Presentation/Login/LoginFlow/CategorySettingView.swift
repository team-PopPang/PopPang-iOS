//
//  CategorySettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct CategorySettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    var onNext: () -> Void
    
    // 카테고리 목록
    private let categories = [
        "애니메이션", "캐릭터", "화장품", "패션",
        "식음료","태크/가전", "문화/전시",
        "생활용품/리빙", "엔터테인먼트",
        "지역/로컬", "콜라보/굿즈"
    ]
    
    // 선택한 카테고리들
    @State private var selectedCategories: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("추천 받고 싶은 항목을\n선택해주세요.")
                        .font(.scdream(.bold, size: 17))
                    Text("선택하신 항목에 맞게 추천해드려요")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                Spacer()
            }
            .padding(.top, 50)
            
            // 선택 버튼들
            FlowLayout(categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategories.contains(category)
                            ) {
                                toggleCategory(category)
                            }
                        }
                        .padding(.top, 30)

            
            Spacer()
            
            MainOrangeButton(buttonTitle: "완료") {
                print(selectedCategories)
                rootViewModel.completeRegistration()
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
    }
    
    
    /// 카테고리 추가/삭제
    /// - Parameter category: 카테고리 타이틀
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}





#Preview {
    CategorySettingView {
    }
    .environmentObject(RootViewModel())
}
