//
//  SearchFlowLayout.swift
//  PopPang
//
//  Created by 김동현 on 10/1/25.
//

import SwiftUI

struct SearchFlowButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.scdream(.regular, size: 9))
                    .foregroundStyle(Color.mainBlack)
                
                Button {
                    print("plus")
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(Color.mainBlack)
                }
                
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1.5)
                    .fill(Color.mainGray5)
            }
        }
    }
}

#Preview {
    SearchFlowButton(title: "화장품") {
        print("keyword")
    }
}
