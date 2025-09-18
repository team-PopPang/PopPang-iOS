//
//  KeywordSettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct KeywordSettingView: View {
    
    var onNext: () -> Void
    var body: some View {

        VStack {
            
            Spacer()
            
            Text("KeywordSettingView")
            
            Spacer()
            
            NextButton(buttonTitle: "다음") {
                DispatchQueue.main.async {
                    onNext()
                }
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    KeywordSettingView {
        
    }
}
