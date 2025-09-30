//
//  SearchView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Alert
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Image("navigationBtn")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(Color.mainBlack)
                }.padding(.trailing, 10)
                
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                text: $searchText)
                .focused($isFocused)
          
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
        .onAppear {
            
            Task { @MainActor in
                isFocused = true
            }
            /*
            DispatchQueue.main.async {
                isFocused = true
            }
             */
        }
    }
}

#Preview {
    SearchView()
}
