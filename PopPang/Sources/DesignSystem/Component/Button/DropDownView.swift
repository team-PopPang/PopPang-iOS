//
//  DropDownView.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import SwiftUI

struct DropDownView: View {
    var hint: String
    var options: [String]
    var anchor: Anchor = .bottom
    var maxWidth: CGFloat = 180
    var cornerRadius: CGFloat = 15
    var stroke: Color = .mainBlack
    var imgSize: CGFloat = 16
    var imgColor: Color = .mainBlack
    @Binding var selection: String?
    var overlay: Bool = false
    @State private var showOptions: Bool = false
    @Environment(\.colorScheme) private var scheme
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var zIndex: Double = 1000.0
    
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            VStack(spacing: 0) {
                
                if showOptions && anchor == .top {
                    OptionsView()
                }
                
                HStack(spacing: 0) {
                    Text(selection ?? hint)
                        .font(.scdream(.medium, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1)
                    
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
                    withAnimation(.snappy) {
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
            .frame(height: size.height, alignment: anchor == .top ? .bottom : .top)
            
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
                        .font(.scdream(.medium, size: 15))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.mainBlack)
                        .opacity(selection == option ? 1 : 0)
                    
                }
                .foregroundStyle(selection == option ? Color.primary : .gray)
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
            DropDownView(hint: "전체",
                         options: [
                            "서울",
                            "부산",
                            "진주"
                         ],
                         anchor: .bottom,
                         maxWidth: 100,
                         selection: $selection)
            
            DropDownView(hint: "select",
                         options: [
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
