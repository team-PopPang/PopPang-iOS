import ComposableArchitecture
import DSKit
import SwiftUI

public struct OnboardingFeatureView: View {
    let store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            content(bottomInset: proxy.safeAreaInsets.bottom)
        }
        .background(Color.subWhite.ignoresSafeArea())
    }

    /// 홈 바가 없는 기기(SE)는 아래 여백이 0이라 버튼이 화면 끝에 붙는다. 그때만 여백을 준다.
    private func content(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            skipButton()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: 37)
                .padding(.horizontal, 20)

            PageView(
                currentStep: Binding(
                    get: { store.currentStep },
                    set: { store.send(.stepChanged($0)) }
                )
            )

            pageIndicator()
                .frame(height: 18)
                .frame(maxWidth: .infinity)

            OnboardingNextButton(
                title: store.currentStep == .favorite
                    ? String(localized: "시작하기", bundle: .module, comment: "Primary CTA to start the app")
                    : String(localized: "다음", bundle: .module, comment: "Primary CTA to continue to the next step"),
                showsArrow: store.currentStep != .favorite
            ) {
                store.send(.nextTapped)
            }
            .padding(.horizontal, 23)
            .padding(.top, 25)
            .padding(.bottom, bottomInset == 0 ? 16 : 0)
        }
    }

    private func skipButton() -> some View {
        Button {
            store.send(.skipTapped)
        } label: {
            Text("건너뛰기", bundle: .module, comment: "Action to skip onboarding")
                .ppStyleFont(.scdream(.medium, size: 14), lineHeightPt: 22)
                .foregroundStyle(Color.onboardingGray)
        }
    }

    private func pageIndicator() -> some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(store.currentStep == step ? Color.mainBlack : Color.onboardingDot)
                    .frame(width: store.currentStep == step ? 17 : 8, height: 8)
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
    }
}

private struct PageContentView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DSKitResource.image(step.card)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: .infinity)
                // 작은 화면에서는 글자 대신 카드가 줄어든다.
                .layoutPriority(-1)

            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 9) {
                DSKitResource.image(step.icon)
                    .resizable()
                    .frame(width: 30, height: 30)

                Text(step.title)
                    .ppStyleFont(.scdream(.extraBold, size: 24), lineHeightPt: 24 * 1.47)
                    .foregroundStyle(Color.subBlack)

                Text(step.content)
                    .ppStyleFont(.scdream(.regular, size: 14), lineHeightPt: 14 * 1.47)
                    .foregroundStyle(Color.onboardingBody)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    var icon: String {
        switch self {
        case .keyword:
            "OnboardingV2IconBell"
        case .map:
            "OnboardingV2IconMapPin"
        case .favorite:
            "OnboardingV2IconCalendar"
        }
    }

    var card: String {
        switch self {
        case .keyword:
            "OnboardingV2Card1"
        case .map:
            "OnboardingV2Card2"
        case .favorite:
            "OnboardingV2Card3"
        }
    }

    var title: String {
        switch self {
        case .keyword:
            String(localized: "놓치기 싫은 팝업,\n키워드만 등록하세요", bundle: .module, comment: "Onboarding title for keyword notifications")
        case .map:
            String(localized: "지금 근처에서 열린 팝업,\n지도로 한눈에", bundle: .module, comment: "Onboarding title for nearby popup map")
        case .favorite:
            String(localized: "가고 싶은 팝업은\n캘린더에 찜해두세요", bundle: .module, comment: "Onboarding title for favorites calendar")
        }
    }

    var content: String {
        switch self {
        case .keyword:
            String(localized: "브랜드, 캐릭터, 지역 키워드를 등록하면\n관련 팝업이 열리는 순간 알려드려요.", bundle: .module, comment: "Onboarding body for keyword notifications")
        case .map:
            String(localized: "지도 앱엔 안 나오는 팝업까지,\n거리와 마감 시간을 함께 보여드려요.", bundle: .module, comment: "Onboarding body for nearby popup map")
        case .favorite:
            String(localized: "캘린더에 한눈에 정리되고,\n날짜별로 바로 확인할 수 있어요", bundle: .module, comment: "Onboarding body for favorites calendar")
        }
    }
}
