//
//  SegmentedControlView.swift
//  PopPang
//
//  Created by 김동현 on 10/5/25.
//

import SwiftUI

struct SegmentedControlView: View {
    @State private var selectedIndex = 0
    private let anyViews: [AnyView]
    
    let segments: [String]
    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont
    
    
    // ✅ 외부에서는 어떤 View든 받을 수 있게 [any View]
    init(segments: [String],
         views: [any View],
         background: Color = .gray.opacity(0.3),
         foreground: Color = .blue,
         height: CGFloat = 4,
         font: UIFont = .scdream(.medium, size: 12)
    ) {
        self.segments = segments
        self.anyViews = views.map { AnyView($0) } // 내부에서 감싸기
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 세그먼트 버튼
            HStack {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(selectedIndex == index ? foreground : background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }
            
            // 인디케이터
            GeometryReader { geometry in
                let segmentWidth = geometry.size.width / CGFloat(segments.count)
                ZStack(alignment: .leading) {
                    Color.mainGray5.frame(height: 2)
                     Capsule()
                        .fill(foreground)
                        .frame(width: segmentWidth, height: height)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
            .frame(height: height)
            
            // TabView
            TabView(selection: $selectedIndex) {
                ForEach(anyViews.indices, id: \.self) { index in
                    anyViews[index]
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
            // 탭뷰용 크기
            // .frame(height: 500)
        }
    }
}
