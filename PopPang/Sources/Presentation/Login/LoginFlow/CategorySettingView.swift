//
//  CategorySettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct Category: Identifiable {
    let id: Int
    let name: String
}

extension Category {
    static let categories: [Category] = [
        .init(id: 101, name: "애니메이션"),
        .init(id: 102, name: "캐릭터"),
        .init(id: 103, name: "화장품"),
        .init(id: 104, name: "패션"),
        .init(id: 105, name: "식음료"),
        .init(id: 106, name: "태크/가전"),
        .init(id: 107, name: "문화/전시"),
        .init(id: 108, name: "생활용품/리빙"),
        .init(id: 109, name: "엔터테인먼트"),
        .init(id: 110, name: "지역/로컬"),
        .init(id: 111, name: "콜라보/굿즈")
    ]
}

struct CategorySettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    var onNext: () -> Void
    
    // 카테고리 목록
    private let categories = Category.categories
    
    // 선택한 카테고리들
    @State private var selectedCategories: [Int] = []
    
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
            FlowLayout(categories, id: \.id) { category in
                            CategoryButton(
                                title: category.name,
                                isSelected: selectedCategories.contains(category.id)
                            ) {
                                toggleCategory(category.id)
                            }
                        }
                        .padding(.top, 30)

            
            Spacer()
            
            MainOrangeButton(buttonTitle: "완료") {
                print(selectedCategories)
                rootViewModel.send(action: .setRecommandList(selectedCategories))
                rootViewModel.send(action: .register)
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
    }
    
    
    /// 카테고리 추가/삭제
    /// - Parameter category: 카테고리 타이틀
    private func toggleCategory(_ categoryid: Int) {
        if let index = selectedCategories.firstIndex(of: categoryid) {
            // 이미 있으면 제거
            selectedCategories.remove(at: index)
        } else {
            // 없으면 추가
            selectedCategories.append(categoryid)
        }
    }
}


#Preview {
    CategorySettingView {
    }
    .environmentObject(RootViewModel())
}
