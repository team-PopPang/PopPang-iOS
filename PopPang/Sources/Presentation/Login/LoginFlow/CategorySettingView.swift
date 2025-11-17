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
    
    // 선택한 카테고리들
    @State private var selectedCategories: [Int] = []
    
    // 다음 스탭 활성화 유무
    private var isNextEnabled: Bool {
        !selectedCategories.isEmpty
    }
    
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
            FlowLayout(rootViewModel.recommandList, id: \.id) { category in
                            CategoryButton(
                                title: category.recommendName,
                                isSelected: selectedCategories.contains(category.id)
                            ) {
                                toggleCategory(category.id)
                            }
                        }
                        .padding(.top, 30)

            
            Spacer()
            
            MainOrangeButton(buttonTitle: "다음",
                             buttonColor: isNextEnabled ? Color.mainOrange : Color.mainGray2) {
                rootViewModel.send(action: .setRecommandList(selectedCategories))
                
                UIApplication.shared.endEditing(true)
                Task {
                    try? await Task.sleep(nanoseconds: 700_000_000) // 0.7초
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onNext()
                    }
                }
                // rootViewModel.send(action: .register)
            }
            // MARK: - 활성화 로직
            .disabled(!isNextEnabled)
            .opacity(isNextEnabled ? 1.0 : 0.8)
            
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
