//
//  RegisterFlowView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

enum RegisterRoute: Int, CaseIterable, Hashable {
    case nickname = 0
    case category
    case keyword
    var index: Int { rawValue }
}

struct RegisterFlowView: View {
    @State private var currentStep: RegisterRoute = .nickname
    @State private var isForward: Bool = true   // 전환 방향 기록
    @EnvironmentObject private var rootViewModel: RootViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션바
            HStack {
                // 닉네임 화면이 아니라면
                if currentStep != .nickname {
                    Button {
                        withAnimation(.easeInOut) {
                            goBack()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.black)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // MARK: - 건너띄기
                    Button {
                        withAnimation(.easeOut) {
                            
                            // 카테고리창이면 키워드 창으로 이동
                            if currentStep == .category {
                                withAnimation(.easeInOut) {
                                    isForward = true
                                    currentStep = .keyword
                                }
                                return
                            }
                            
                            // 현재 키워드창이면 회원가입
                            if currentStep == .keyword {
                                rootViewModel.send(action: .register)
                                return
                            }
                            
                        }
                    } label: {
                        Text("건너뛰기")
                            .ppStyleFont(.scdream(.regular, size: 13))
                            .foregroundStyle(Color.mainGray)
                            .padding()
                    }
                    
                    // 닉네임 화면이라면
                } else {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .opacity(0)
                        .padding()
                    Spacer()
                }
            }
            .frame(height: 44)
            .background(Color.white)
            
            // 주황색 프로그래스바
            ProgressView(value: Double(currentStep.index + 1),
                         total: Double(RegisterRoute.allCases.count))
            .progressViewStyle(.linear)
            .tint(.orange)
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            GeometryReader { geo in
                ZStack {
                    NicknameSettingView {
                        withAnimation(.easeInOut) {
                            isForward = true
                            currentStep = .category
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: offset(for: .nickname, in: geo.size.width))
                    
                    CategorySettingView {
                        withAnimation(.easeInOut) {
                            isForward = true
                            currentStep = .keyword
                        }
                        
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: offset(for: .category, in: geo.size.width))
                    
                    KeywordSettingView {
                        print("회원가입 완료")
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: offset(for: .keyword, in: geo.size.width))
                }
            }
            .clipped()
        }
    }
    
    private func goBack() {
        isForward = false
        switch currentStep {
        case .category: currentStep = .nickname
        case .keyword: currentStep = .category
        default: break
        }
    }
    
    // 👉 현재 단계에 맞게 좌우 오프셋 적용
    private func offset(for route: RegisterRoute, in width: CGFloat) -> CGFloat {
        let diff = route.index - currentStep.index
        return CGFloat(diff) * width
    }
}

#Preview {
    RegisterFlowView()
        .environmentObject(RootViewModel())
}
