//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                SearchTextField(placeholder: "궁금한 장소를 검색해보세요", text: $searchText)
                
                AlertButton {
                    
                }
                .padding(.leading, .contentPadding)
                
            }
            
            Spacer()
        }
        .padding(.contentPadding)
    }
}

private struct AlertButton: View {
    var action: () -> Void
    
    var body: some View {
        Image("Bell")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .padding(10)
    }
}

#Preview {
    HomeView()
}

