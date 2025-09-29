//
//  SearchView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Alert
            HStack(spacing: 0) {
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                text: $searchText)
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                }
                
                IconButton {
                    print("알림 버튼 클릭됨")
                    coordinator.presentOverlay(overlay: .notice(title: "공지사항",
                                                                content: "키워드 화면 구현 예정입니다."))
                }
                .padding(.leading, .contentPadding)
            }
            .padding(.top, .contentPadding)
            .padding(.horizontal, .contentPadding)
            .padding(.bottom, 10)
            
            Spacer()
        }
    }
}

#Preview {
    SearchView()
}
