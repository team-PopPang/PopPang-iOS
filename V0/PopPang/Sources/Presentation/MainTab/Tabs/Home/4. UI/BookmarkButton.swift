//
//  BookmarkButton.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI

// MARK: - 찜버튼
struct BookmarkButton: View {
    enum Info {
        case fill
        case stroke
    }
    var isLiked: Bool
    var info: Info
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            switch info {
            case .fill:
                Image(isLiked ? "favorite_fill" : "favorite")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            case .stroke:
                Image(isLiked ? "favorite_fill" : "favorite")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(isLiked ? Color.mainOrange : Color.subWhite)
            }
        }
    }
}
