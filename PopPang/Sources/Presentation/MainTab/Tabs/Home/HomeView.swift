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
            SearchTextField(placeholder: "궁금한 장소를 검색해보세요", text: $searchText)
            
            Spacer()
        }
        .padding(.contentPadding)
    }
}

#Preview {
    HomeView()
}

