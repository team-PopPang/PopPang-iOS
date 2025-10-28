//
//  DropDownView.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import SwiftUI

/*
 DropDownView(options: [
                 "전체",
                 "서울",
                 "부산",
                 "진주"
              ],
              anchor: .bottom,
              maxWidth: 90,
              selection: $selectRegion,
              overlay: false,
              pickedFont: .scdream(.medium, size: 17),
              detailFont: .scdream(.medium, size: 17)
 )
 .padding(.leading, -10)
 
 DropDownView(options: [
                 "찜순",
                 "가까운순",
              ],
              anchor: .bottom,
              maxWidth: 90,
              cornerRadius: 17,
              stroke: .mainGray5,
              imgSize: 10,
              imgColor: .mainGray2,
              selection: $selectSort,
              overlay: true,
              pickedFont: .scdream(.light, size: 10),
              detailFont: .scdream(.light, size: 10)
             
 )
 */

struct DropDownView: View {
    var options: [String]
    var anchor: Anchor = .bottom
    var maxWidth: CGFloat = 180
    var cornerRadius: CGFloat = 15
    var stroke: Color = .mainBlack
    var imgSize: CGFloat = 16
    var imgColor: Color = .mainBlack
    @Binding var selection: String?
    var overlay: Bool = false
    // 글자 관련
    var pickedFont: Font = .scdream(.medium, size: 15)
    var pickedColor: Color = Color.mainBlack
    
    var detailFont: Font = .scdream(.medium, size: 15)
    var detailClicked: Color = Color.mainBlack
    var detailNotClicked: Color = Color.mainGray
    
    
    @State private var showOptions: Bool = false
    @Environment(\.colorScheme) private var scheme
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var zIndex: Double = 1000.0
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            VStack(spacing: 0) {
                
                if showOptions && anchor == .top {
                    OptionsView()
                }
                
                HStack(spacing: 0) {
                    Text(selection ?? "")
                        .font(pickedFont)
                        .foregroundStyle(pickedColor)
                        .lineLimit(1)
                        .animation(.none, value: selection)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imgSize, height: imgSize)
                        .foregroundStyle(imgColor)
                        .rotationEffect(.init(degrees: showOptions ? -180 : 0))
                }
                .padding(.horizontal, 15)
                .frame(width: size.width, height: size.height)
                .background(scheme == .dark ? .black : .white)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
                        index += 1
                        zIndex = index
                        showOptions.toggle()
                    }
                }
                .zIndex(10)
                
                if showOptions && anchor == .bottom {
                    OptionsView()
                }
            }
            .clipped()
            .background(.white)
            .cornerRadius(cornerRadius)
            .overlay {
                if overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(stroke)
                }
            }
            .frame(height: size.height,
                   alignment: anchor == .top ? .bottom : .top)
            // ✅ 첫 번째 옵션 기본 선택
            .onAppear {
                if selection == nil {
                    selection = options.first
                }
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: 40)
        .zIndex(zIndex)
    }
    
    @ViewBuilder
    func OptionsView() -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                HStack (spacing: 0) {
                    Text(option)
                        .font(detailFont)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.mainBlack)
                        .opacity(selection == option ? 1 : 0)
                }
                .foregroundStyle(selection == option ? detailClicked : detailNotClicked)
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selection = option
                        showOptions = false
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .transition(.move(edge: anchor == .top ? .bottom : .top))
    }
    
    enum Anchor {
        case top
        case bottom
    }
}

struct TestView: View {
    @State private var selection: String?
    @State private var selection1: String?
    @State private var selection2: String?
    var body: some View {
        VStack {
            DropDownView(options: [
                            "서울",
                            "부산",
                            "진주"
                         ],
                         anchor: .bottom,
                         maxWidth: 100,
                         selection: $selection)
            
            DropDownView(options: [
                            "서울",
                            "부산",
                            "진주"
                         ],
                         anchor: .top,
                         selection: $selection1,
                         overlay: true
            )
            Menu {
                Button("서울") { print("서울 선택") }
                Button("부산") { print("부산 선택") }
                Button("대구") { print("대구 선택") }
            } label: {
                Label("전체", systemImage: "chevron.down")
            }

            Picker("지역 선택", selection: $selection2) {
                Text("전체").tag("전체")
                Text("서울").tag("서울")
                Text("부산").tag("부산")
            }
            .pickerStyle(.menu) // 드롭다운처럼 보이게
            
    
        }
    }
}

#Preview {
    TestView()
}
