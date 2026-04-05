//
//  Onboadring.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct OnboadringView: View {
    @EnvironmentObject private var coordinator: Coordinator<OnboardingRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @State private var currentStep: OnboardingStep = .keyword
    
    var body: some View {
        NavigationStack(path: $coordinator.paths) {
            ZStack(alignment: .topTrailing) {
                
                Color.subWhite3.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // MARK: - 컨텐츠
                    PageView(currentStep: $currentStep)
                    
                    // MARK: - 하단 영역
                    VStack(spacing: 0) {
                        // MARK: - 인디케이터
                        pageIndicator()
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                        
                        // MARK: - 다음 버튼
                        MainOrangeButton(
                            buttonTitle: currentStep == .favorite
                            ? NSLocalizedString("common.start", comment: "Primary CTA to start the app")
                            : NSLocalizedString("common.next", comment: "Primary CTA to continue to the next step")
                        ) {
                            if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
                                currentStep = OnboardingStep.allCases[currentStep.rawValue + 1]
                            } else {
                                coordinator.push(.login)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                    }
                    .padding(.top, 20)
                    .background(Color.subWhite)
                }
                
                // MARK: - 건너뒤기 버튼
                Button {
                    coordinator.push(.login)
                } label: {
                    Text(NSLocalizedString("common.skip", comment: "Action to skip onboarding"))
                        .font(.scdream(.regular, size: 12))
                        .foregroundColor(Color.mainBlack)
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                coordinator.buildView(for: route)
            }
            
        }
    }
    
    private func pageIndicator() -> some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) {
                Capsule()
                    .fill(currentStep == $0 ? Color.mainBlack : .gray)
                    .frame(width: currentStep == $0 ? 12 : 6,
                           height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
}

private struct PageView: View {
    @Binding var currentStep: OnboardingStep
    
    var body: some View {
        TabView(selection: $currentStep) {
            ForEach(OnboardingStep.allCases, id: \.self) {
                PageContentView(step: $0).tag($0)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(duration: 0.5), value: currentStep)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct PageContentView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            Image(step.logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding(.top, 90)
            
            Text(step.title)
                .font(.scdream(.extraBold, size: 18))
                .padding(.top, 20)
            
            Text(step.content)
                .font(.scdream(.regular, size: 15))
                .foregroundStyle(Color.subBlack2)
                .padding(.top, 10)
            
            Spacer()
            
            Image(step.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UIScreen.main.bounds.height * 0.45, alignment: .bottom)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        // .background(.blue)
    }
}

#Preview {
    OnboadringView()
        .environmentObject(Coordinator<OnboardingRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
}




//.frame(height: UIScreen.main.bounds.height * 0.45, alignment: .top) // 높이를 줄여 상단만 노출
//.clipped()                // 남는 부분 잘라내기
