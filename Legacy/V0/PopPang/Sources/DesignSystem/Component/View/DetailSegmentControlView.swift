//
//  DetailSegmentControlView.swift
//  PopPang
//
//  Created by 김동현 on 12/31/25.
//

import SwiftUI

struct DetailSegmentedControlView_Save: View {
    @State private var selectedIndex = 0
    
    private let segments: [String]
    private let views: [AnyView]
    
    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont

    init(
        segments: [String],
        views: [any View],
        background: Color = .gray.opacity(0.3),
        foreground: Color = .blue,
        height: CGFloat = 3,
        font: UIFont = .systemFont(ofSize: 13, weight: .medium)
    ) {
        self.segments = segments
        self.views = views.map { AnyView($0) }
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segment Buttons
            HStack(spacing: 0) {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(
                                selectedIndex == index ? foreground : .secondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            // MARK: - Indicator
            GeometryReader { geo in
                let width = geo.size.width / CGFloat(segments.count)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(background)
                        .frame(height: height)

                    Capsule()
                        .fill(foreground)
                        .frame(width: width, height: height)
                        .offset(x: CGFloat(selectedIndex) * width)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
            .frame(height: height)
            .padding(.bottom, 4)

            // MARK: - Content (TabView 대체)
            ZStack {
                ForEach(views.indices, id: \.self) { index in
                    if selectedIndex == index {
                        views[index]
                            .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut, value: selectedIndex)
        }
    }
}

struct DetailSegmentedControlView: View {
    @State private var selectedIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let segments: [String]
    private let views: [AnyView]

    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont

    init(
        segments: [String],
        views: [any View],
        background: Color = .gray.opacity(0.3),
        foreground: Color = .blue,
        height: CGFloat = 3,
        font: UIFont = .systemFont(ofSize: 13, weight: .medium)
    ) {
        self.segments = segments
        self.views = views.map { AnyView($0) }
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Segment Buttons
            HStack(spacing: 0) {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(
                                selectedIndex == index ? foreground : .secondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            // MARK: - Indicator
            GeometryReader { geo in
                let width = geo.size.width / CGFloat(segments.count)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(background)
                        .frame(height: height)

                    Capsule()
                        .fill(foreground)
                        .frame(width: width, height: height)
                        .offset(x: CGFloat(selectedIndex) * width)
                        .animation(.easeInOut, value: selectedIndex)
                }
            }
            .frame(height: height)
            .padding(.bottom, 6)

            // MARK: - Sliding Content
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(views.indices, id: \.self) { index in
                        views[index]
                            .frame(width: geo.size.width)
                    }
                }
                .offset(x: -CGFloat(selectedIndex) * geo.size.width + dragOffset)
                .animation(.easeInOut, value: selectedIndex)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let threshold = geo.size.width / 4
                            if value.translation.width < -threshold {
                                selectedIndex = min(selectedIndex + 1, views.count - 1)
                            } else if value.translation.width > threshold {
                                selectedIndex = max(selectedIndex - 1, 0)
                            }
                        }
                ).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


struct AView: View {
    var body: some View {
        VStack {
            Text("AView")
        }
    }
}

struct BView: View {
    var body: some View {
        VStack {
            Text("BView!")
        }
    }
}

struct CView: View {
    var body: some View {
        VStack {
            Text("CView")
        }
    }
}

struct DetailTestView: View {
    var body: some View {
        DetailSegmentedControlView(
            segments: ["공지", "이벤트", "쿠폰"],
            views: [
                AView(),
                BView(),
                CView()
            ],
            foreground: .blue
        )
    }
}

//#Preview {
//    DetailTestView()
//}

struct SegmentHeader: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                segmentButton("정보", 0)
                segmentButton("리뷰", 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()
        }
        .background(Color.white)
    }

    func segmentButton(_ title: String, _ index: Int) -> some View {
        Button {
            withAnimation {
                selectedIndex = index
            }
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(selectedIndex == index ? .black : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}


struct PopupDetailSampleView: View {
    @State private var selectedIndex = 0

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {

                // 🔹 상단 콘텐츠 (스크롤됨)
                VStack(alignment: .leading, spacing: 16) {
//                    Rectangle()
//                        .fill(Color.blue.opacity(0.3))
//                        .frame(height: 250)
//                        .overlay(Text("이미지 영역"))

                    Text("쿠키런 팝업스토어")
                        .font(.title2)
                        .bold()

                    Text("전시 설명 텍스트가 들어가는 영역입니다.")
                        .foregroundColor(.secondary)
                }
                .padding()

                // 🔹 고정될 세그먼트
                Section(
                    header: SegmentHeader(selectedIndex: $selectedIndex)
                ) {
                    SegmentContent(selectedIndex: selectedIndex)
                }
            }
        }
    }
}

struct SegmentContent: View {
    let selectedIndex: Int

    var body: some View {
        Group {
            if selectedIndex == 0 {
                InfoSection()
            } else {
                ReviewSection()
            }
        }
        .padding()
    }
}

struct InfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<6) { _ in
                Text("정보 내용입니다.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ReviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<10) { i in
                Text("리뷰 \(i + 1)")
            }
        }
    }
}

#Preview {
    PopupDetailSampleView()
}
