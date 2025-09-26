//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute>
    @State private var searchText = ""
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                text: $searchText)
                .disabled(true)
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            coordinator.push(.search)
                        }
                }
                
                AlertButton {
                    print("알림 버튼 클릭됨")
                    coordinator.push(.alert)
                }
                .padding(.leading, .contentPadding)
                
            }
            
            Spacer()
        }
        .padding(.contentPadding)
    }
}

#Preview {
    HomeView()
}

