//
//  SearchFlowLayout.swift
//  PopPang
//
//  Created by 김동현 on 10/1/25.
//

import SwiftUI

struct SearchFlowButton: View {
    let title: String
    let action: () -> Void   // 버튼 이벤트
    let onRemove: () -> Void // x 버튼 이벤트
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Text(title)
                    .font(.scdream(.regular, size: 9))
                    .foregroundStyle(Color.mainBlack)
                
                Button {
                    onRemove()
                } label: {
                    Image("removeBtn")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(Color.mainBlack)
                        .padding(5)
                }
                
            }
            //.padding(.vertical, 2)
            .padding(.leading, 14)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1.5)
                    .fill(Color.mainGray5)
            }
        }
    }
}

//#Preview {
//    SearchFlowButton(title: "화장품") {
//        print("keyword")
//    }
//}

/// 검색 FlowLayout
///  data: 보여줄 원본 데이터 배열
///  id: 각 아이템 고유 식별자
///  content 데이터를 실제 뷰로 변환하는 클로저
struct SearchFlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content
    
    init(data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
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
    
    @Previewable @State var searched = [
        "애니메이션", "캐릭터", "화장품", "패션",
        "식음료"
    ]
    
    SearchFlowLayout(data: searched, id: \.self) { search in
        SearchFlowButton(title: search) {
            print("keyword")
        } onRemove: {
            if let index = searched.firstIndex(of: search) {
                searched.remove(at: index)
            }
        }
    }
}

