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
            
            NextButton(buttonTitle: "완료") {
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


/// 카테고리 선택버튼
/// - title
/// - isSelected
/// - action
private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        // 테두리
                        .strokeBorder(isSelected ? Color.mainOrange : .clear, lineWidth: 1.5)
                        // 배경
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isSelected ? Color.categoryOrange : Color.mainGray4)
                        }
                }
                // 텍스트
                .foregroundStyle(isSelected ? Color.mainOrange : Color.mainGray2)
        }
    }
}

/// 카테고리 FlowLayout
///  data: 보여줄 원본 데이터 배열
///  id: 각 아이템 고유 식별자
///  content 데이터를 실제 뷰로 변환하는 클로저
private struct FlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content
    
    init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content
    }
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(data, id: id) { item in
                    content(item)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading, computeValue: { d in
                            if abs(width - d.width) > geo.size.width {
                                // 한 줄 넘어가면 줄바꿈
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item[keyPath: id] == data.last?[keyPath: id] {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = height
                            if item[keyPath: id] == data.last?[keyPath: id] {
                                height = 0
                            }
                            return result
                        })
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    CategorySettingView {
    }
    .environmentObject(RootViewModel())
//    @Previewable @State var test: Bool = false
//    CategoryButton(title: "테스트",
//                   isSelected: test) {
//        test.toggle()
//    }
}
