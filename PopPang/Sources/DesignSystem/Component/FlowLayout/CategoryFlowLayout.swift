//
//  CategoryFlowLayout.swift
//  PopPang
//
//  Created by 김동현 on 10/1/25.
//

import SwiftUI


/// 카테고리 선택버튼
/// - title
/// - isSelected
/// - action
struct CategoryButton: View {
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
struct FlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View {
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
    @Previewable @State var test = false
    VStack(spacing: 20) {
        CategoryButton(title: "테스트", isSelected: test) {
            test.toggle()
        }
        
        let categories = [
            "애니메이션", "캐릭터", "화장품", "패션",
            "식음료","태크/가전", "문화/전시",
            "생활용품/리빙", "엔터테인먼트",
            "지역/로컬", "콜라보/굿즈"
        ]
        
        FlowLayout(categories, id: \.self) { category in
            CategoryButton(
                title: category,
                isSelected: false
            ) { }
        }
    }
    .padding()
}
