//
//  Onboadring.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct OnboadringView: View {
    @EnvironmentObject private var coordinator: Coordinator<OnboardingRoute, SheetRoute>
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        NavigationStack(path: $coordinator.paths) {
            VStack(spacing: 0) {
                Spacer()
                PageView(currentStep: $currentStep)
                Spacer()
                
                // MARK: - 인디케이터
                pageIndicator()
                    .frame(maxWidth: .infinity)
                
                // MARK: - 다음 버튼
                NextButton(
                    buttonTitle: currentStep == .favorite ? "로그인" : "다음"
                ) {
                    if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
                        currentStep = OnboardingStep.allCases[currentStep.rawValue + 1]
                    } else {
                        coordinator.push(.login)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
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
                    .fill(currentStep == $0 ? .orange : .gray)
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
    }
}

private struct PageContentView: View {
    let step: OnboardingStep
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {
                Text(step.title)
                    .font(.scdream(.extraBold, size: 20))
                    .padding(.top, proxy.size.height * 0.3)
                
                Text(step.content)
                    .font(.scdream(.medium, size: 16))
                    .padding(.top, proxy.size.height * 0.1)
                
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    OnboadringView()
}
