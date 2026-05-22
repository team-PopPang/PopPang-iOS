import DSKit
import SwiftUI

public struct OnboardingFeatureView: View {
    private let onSkip: () -> Void
    private let onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .keyword

    public init(
        onSkip: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {}
    ) {
        self.onSkip = onSkip
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.subWhite3.ignoresSafeArea()

            VStack(spacing: 0) {
                PageView(currentStep: $currentStep)

                VStack(spacing: 0) {
                    pageIndicator()
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 20)

                    MainOrangeButton(
                        buttonTitle: currentStep == .favorite ? "시작하기" : "다음"
                    ) {
                        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
                            currentStep = OnboardingStep.allCases[currentStep.rawValue + 1]
                        } else {
                            onComplete()
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
                .padding(.top, 20)
                .background(Color.subWhite)
            }

            Button {
                onSkip()
            } label: {
                Text("건너뛰기")
                    .font(.scdream(.regular, size: 12))
                    .foregroundColor(Color.mainBlack)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }

    private func pageIndicator() -> some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(currentStep == step ? Color.mainBlack : .gray)
                    .frame(
                        width: currentStep == step ? 12 : 6,
                        height: 6
                    )
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
}

private struct PageView: View {
    @Binding var currentStep: OnboardingStep

    var body: some View {
        TabView(selection: $currentStep) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                PageContentView(step: step).tag(step)
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
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case keyword = 0
    case map
    case favorite

    var logo: String {
        switch self {
        case .keyword:
            "Logo1"
        case .map:
            "Logo2"
        case .favorite:
            "Logo3"
        }
    }

    var title: String {
        switch self {
        case .keyword:
            "팝업스토어 알림"
        case .map:
            "위치 기반 서비스"
        case .favorite:
            "캘린더형 찜 리스트"
        }
    }

    var content: String {
        switch self {
        case .keyword:
            "키워드를 등록하여 원하는 팝업 알림을 받아보세요。"
        case .map:
            "내 주변에서 열리는 팝업을 바로 확인하세요。"
        case .favorite:
            "찜한 팝업을 날짜별로 확인할 수 있어요。"
        }
    }

    var image: String {
        switch self {
        case .keyword:
            "Onboarding1"
        case .map:
            "Onboarding2"
        case .favorite:
            "Onboarding3"
        }
    }
}
