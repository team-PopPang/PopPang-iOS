//
//  LaunchView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            Image("Launch")
                .resizable()
                .scaledToFill()   // 화면 꽉 채우기
                .ignoresSafeArea()
        }
    }
}

#Preview {
    LaunchView()
}
