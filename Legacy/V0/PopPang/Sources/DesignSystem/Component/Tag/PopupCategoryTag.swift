//
//  PopupCategoryTag.swift
//  PopPang
//
//  Created by 김동현 on 11/26/25.
//

import SwiftUI

// MARK: - Tag
struct PopupCategoryTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .ppStyleFont(.scdream(.regular, size: 11))
            .foregroundStyle(Color.subOrange)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.subOrange2)
            .cornerRadius(10)
    }
}


#Preview {
    PopupCategoryTag(text: "태그")
}
