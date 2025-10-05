//
//  AlertView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertView: View {
    @State private var selectedIndex = 0
    private let segments = ["활동", "키워드 설정"]
    
    var body: some View {
        VStack(spacing: 0) {

            // ✅ 세그먼트 헤더
            // SegmentHeader(segments: segments, selectedIndex: $selectedIndex)
            SegmentedControlView(segments: segments,
                          views: [AView(), BView()],
                          background: .mainGray,
                          foreground: .mainOrange)
        }
        // toolbar
        .toolbar {
            // 커스텀 타이틀
            ToolbarItem(placement: .principal) {
                Text("알림")
                    .ppStyleFont(.scdream(.medium, size: 20))
                    .padding(.top, 10)
            }
            
            // 커스텀 우측
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image("gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertView()
    }
}

struct AView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.3).ignoresSafeArea()
        }
    }
}

struct BView: View {
    var body: some View {
        ZStack {
            Color.green.opacity(0.3).ignoresSafeArea()
        }
    }
}

