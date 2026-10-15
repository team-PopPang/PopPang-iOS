import ComposableArchitecture
import DSKit
import SwiftUI

public struct OnboardingFeatureView: View {
    let store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.subWhite3.ignoresSafeArea()

            VStack(spacing: 0) {
                PageView(
                    currentStep: Binding(
                        get: { store.currentStep },
                        set: { store.send(.stepChanged($0)) }
                    )
                )

                VStack(spacing: 0) {
                    pageIndicator()
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 20)

                    MainOrangeButton(
                        buttonTitle: store.currentStep == .favorite
                            ? String(localized: "시작하기", bundle: .module, comment: "Primary CTA to start the app")
                            : String(localized: "다음", bundle: .module, comment: "Primary CTA to continue to the next step")
                    ) {
                        store.send(.nextTapped)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
                .padding(.top, 20)
                .background(Color.subWhite)
            }

            Button {
                store.send(.skipTapped)
            } label: {
                Text("건너뛰기", bundle: .module, comment: "Action to skip onboarding")
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
                    .fill(store.currentStep == step ? Color.mainBlack : .gray)
                    .frame(
                        width: store.currentStep == step ? 12 : 6,
                        height: 6
                    )
            }
        }
        .animation(.easeInOut(duration: 0.5), value: store.currentStep)
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
            DSKitResource.image(step.logo)
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

            DSKitResource.image(step.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UIScreen.main.bounds.height * 0.45, alignment: .bottom)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

public enum OnboardingStep: Int, CaseIterable, Sendable {
    case keyword = 0
    case map
    case favorite

    var next: OnboardingStep? {
        guard rawValue < Self.allCases.count - 1 else { return nil }
        return Self.allCases[rawValue + 1]
    }

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
            String(localized: "팝업스토어 알림", bundle: .module, comment: "Onboarding title for keyword notifications")
        case .map:
            String(localized: "위치 기반 서비스", bundle: .module, comment: "Onboarding title for map-based service")
        case .favorite:
            String(localized: "캘린더형 찜 리스트", bundle: .module, comment: "Onboarding title for favorites calendar")
        }
    }

    var content: String {
        switch self {
        case .keyword:
            String(localized: "키워드를 등록하여 원하는 팝업 알림을 받아보세요.", bundle: .module, comment: "Onboarding body for keyword notifications")
        case .map:
            String(localized: "내 주변에서 열리는 팝업을 바로 확인하세요.", bundle: .module, comment: "Onboarding body for nearby popup map")
        case .favorite:
            String(localized: "찜한 팝업을 날짜별로 확인할 수 있어요.", bundle: .module, comment: "Onboarding body for favorites calendar")
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
