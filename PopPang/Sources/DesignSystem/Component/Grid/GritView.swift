//
//  GritView.swift
//  PopPang
//
//  Created by 김동현 on 10/16/25.
//

import SwiftUI
import Kingfisher

struct GritView: View {
    
    let imageURLs: [String] = [
        "https://picsum.photos/300/400",
        "https://picsum.photos/301/400",
        "https://picsum.photos/302/400",
        "https://picsum.photos/303/400",
        "https://picsum.photos/304/400",
    ]
    
    let columns: [GridItem] = [
        // 좌우간격
        GridItem(.flexible(), spacing: 15, alignment: nil),
        GridItem(.flexible(), spacing: nil, alignment: nil),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns,
                      alignment: .center,
                      spacing: 20, // 위아래 간격
                      pinnedViews: []
            ) {
                ForEach(imageURLs, id: \.self) { url in
                    KFImage(URL(string: url))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 217)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill) // 셀 크기에 이미지를 “꽉 채우되” 원본 비율을 유지(이때 여백이 생기면 잘라냄.)
                        .frame(height: 217)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    GritView()
}
