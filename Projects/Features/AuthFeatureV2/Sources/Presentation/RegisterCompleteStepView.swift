import DSKit
import SwiftUI

/// 가입 완료 화면 (피그마 2467-10931)
struct RegisterCompleteStepView: View {
    let nickname: String
    /// 카드 1번 설명. 고른 카테고리와 키워드를 " · "로 이은 글이다.
    let interestSummary: String
    let isSubmitting: Bool
    let onStart: () -> Void

    var body: some View {
        GeometryReader { proxy in
            content(isCompact: proxy.size.height < CompleteLayout.compactHeight)
        }
    }

    /// 낮은 화면(SE)에서는 아이콘·카드 위 간격을 줄여 카드와 버튼이 붙지 않게 한다.
    private func content(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            doneIcon
                .padding(.top, isCompact ? CompleteLayout.compactIconTop : CompleteLayout.iconTop)

            title
                .padding(.top, CompleteLayout.titleTop)

            benefitCard
                .padding(.top, isCompact ? CompleteLayout.compactCardTop : CompleteLayout.cardTop)

            Spacer(minLength: CompleteLayout.titleTop)

            RegisterNextButton(
                title: String(localized: "알림 켜고 시작하기", bundle: .module, comment: "Button on the sign-up complete screen that asks for notification permission and opens the main screen"),
                isEnabled: !isSubmitting,
                action: onStart
            )
            .padding(.horizontal, RegisterLayout.buttonHorizontal - RegisterLayout.screenHorizontal)
        }
        .padding(.horizontal, RegisterLayout.screenHorizontal)
    }

    private var doneIcon: some View {
        ZStack {
            Circle()
                .fill(Color.registerChipSelected)
                .frame(width: CompleteLayout.iconOuter, height: CompleteLayout.iconOuter)
            Circle()
                .fill(Color.mainOrange)
                .frame(width: CompleteLayout.iconInner, height: CompleteLayout.iconInner)
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.subWhite)
        }
        .accessibilityHidden(true)
    }

    private var title: some View {
        let name = Text(verbatim: nickname).foregroundStyle(Color.mainOrange)
        return VStack(spacing: 4) {
            Text("준비 끝!", bundle: .module, comment: "First line of the sign-up complete title")
            Text("\(name)님, 환영해요", bundle: .module, comment: "Second line of the sign-up complete title. The argument is the user's nickname")
        }
        .ppStyleFont(.scdream(.extraBold, size: 26), lineHeightPt: 31)
        .foregroundStyle(Color.registerTitle)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var benefitCard: some View {
        VStack(alignment: .leading, spacing: CompleteLayout.itemSpacing) {
            BenefitRow(
                title: Text("키워드 팝업 오픈 알림", bundle: .module, comment: "Benefit on the sign-up complete card: alerts when a popup matching your keywords opens"),
                description: Text(verbatim: interestSummary)
            )
            BenefitRow(
                title: Text("찜한 팝업 종료 하루 전 알림", bundle: .module, comment: "Benefit on the sign-up complete card: alert one day before a saved popup ends"),
                description: Text("마지막 기회를 놓치지 않게", bundle: .module, comment: "Description of the saved popup ending alert")
            )
            BenefitRow(
                title: Text("받을 알림은 직접 고를 수 있어요", bundle: .module, comment: "Benefit on the sign-up complete card: you can choose which alerts to get"),
                description: Text("마이 > 알림 설정에서 언제든 바꿀 수 있어요", bundle: .module, comment: "Where to change alert settings later")
            )
        }
        .padding(CompleteLayout.cardPadding)
        .frame(maxWidth: CompleteLayout.cardMaxWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CompleteLayout.cardRadius)
                .fill(Color.subWhite)
                // 피그마 그림자 값을 읽지 못해 그림과 비슷하게 맞춘다 (A-7).
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
        )
    }
}

private struct BenefitRow: View {
    let title: Text
    let description: Text

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.registerChipSelected)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.mainOrange)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                title
                    .ppStyleFont(.scdream(.medium, size: 16), lineHeightPt: 19)
                    .foregroundStyle(Color.registerTitle)
                description
                    .ppStyleFont(.scdream(.light, size: 13), lineHeightPt: 15.5)
                    .foregroundStyle(Color.onboardingGray)
            }
            .padding(.top, 2)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 완료 화면 피그마 값. 상단 바(37) 자리를 뺀 위치다.
private enum CompleteLayout {
    static let iconTop: CGFloat = 63
    static let iconOuter: CGFloat = 84
    static let iconInner: CGFloat = 58
    static let titleTop: CGFloat = 20
    static let cardTop: CGFloat = 62
    static let cardMaxWidth: CGFloat = 338
    static let cardRadius: CGFloat = 15
    static let cardPadding: CGFloat = 26
    static let itemSpacing: CGFloat = 22
    /// 이보다 낮으면(SE 약 594) 간격을 줄인다. iPhone 17은 약 741이다.
    static let compactHeight: CGFloat = 680
    static let compactIconTop: CGFloat = 16
    static let compactCardTop: CGFloat = 28
}
