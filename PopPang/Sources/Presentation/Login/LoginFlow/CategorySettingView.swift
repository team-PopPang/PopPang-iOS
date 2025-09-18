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
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("CategorySettingView")
            
            Spacer()
            
            NextButton(buttonTitle: "완료") {
                rootViewModel.completeRegistration()
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    CategorySettingView {
        
    }
}
