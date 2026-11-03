import ComposableArchitecture
import Domain
import DSKit
import SwiftUI

public struct RegisterFlowFeatureView: View {
    let store: StoreOf<RegisterFlowFeature>

    public init(store: StoreOf<RegisterFlowFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            content(bottomInset: proxy.safeAreaInsets.bottom)
        }
        .background(Color.subWhite.ignoresSafeArea())
        .task {
            store.send(.onAppear)
        }
    }

    /// 홈 바가 없는 기기(SE)는 아래 여백이 0이라 버튼이 화면 끝에 붙는다. 그때만 여백을 준다 (온보딩 V2와 같음).
    private func content(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            RegisterHeader(
                step: min(store.currentStep.index + 1, RegisterRoute.inputSteps.count),
                totalSteps: RegisterRoute.inputSteps.count,
                // 닉네임 단계는 돌아갈 가입 단계가 없다.
                showsBack: store.currentStep != .nickname
            ) {
                store.send(.backTapped)
            }
            // 완료 화면에서는 숨긴다. 자리는 남겨 두어 옆으로 밀리는 단계 화면 높이가 바뀌지 않게 한다.
            .opacity(store.currentStep == .complete ? 0 : 1)
            .allowsHitTesting(store.currentStep != .complete)
            .animation(.easeInOut(duration: 0.3), value: store.currentStep)
            stepPages
                .padding(.bottom, bottomInset == 0 ? RegisterLayout.noHomeBarBottom : 0)
        }
    }

    private var stepPages: some View {
        GeometryReader { geo in
            ZStack {
                NicknameSettingStepView(
                    nickname: Binding(
                        get: { store.nickname },
                        set: { store.send(.nicknameChanged($0)) }
                    ),
                    validationState: store.validationState,
                    errorMessage: store.errorMessage,
                    isSubmitting: store.isSubmitting,
                    isRecommending: store.isRecommendingNickname,
                    onValidate: {
                        store.send(.validateNicknameTapped)
                    },
                    onRecommend: {
                        store.send(.recommendNicknameTapped)
                    },
                    onNext: {
                        store.send(.nextFromNicknameTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .nickname, in: geo.size.width))
                .stepInteraction(isCurrent: store.currentStep == .nickname)

                CategorySettingStepView(
                    recommendList: store.recommendList,
                    selectedCategories: store.selectedCategories,
                    isLoadFailed: store.isRecommendListLoadFailed,
                    onToggle: { store.send(.categoryToggled($0)) },
                    onRetry: { store.send(.retryRecommendListTapped) },
                    onNext: {
                        store.send(.nextFromCategoryTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .category, in: geo.size.width))
                .stepInteraction(isCurrent: store.currentStep == .category)

                KeywordSettingStepView(
                    text: Binding(
                        get: { store.keywordInput },
                        set: { store.send(.keywordInputChanged($0)) }
                    ),
                    keywords: store.keywords,
                    popularKeywords: store.popularKeywords,
                    isSubmitting: store.isSubmitting,
                    errorMessage: store.errorMessage,
                    onAddKeyword: { store.send(.keywordAdded($0)) },
                    onAddPopularKeyword: { store.send(.popularKeywordTapped($0)) },
                    onRemoveKeyword: { store.send(.keywordRemoved($0)) },
                    isLimitAlertPresented: Binding(
                        get: { store.isKeywordLimitAlertPresented },
                        set: { if !$0 { store.send(.keywordLimitAlertDismissed) } }
                    ),
                    onSkip: { store.send(.skipTapped) },
                    onNext: {
                        store.send(.completeRegistrationTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .keyword, in: geo.size.width))
                .stepInteraction(isCurrent: store.currentStep == .keyword)

                RegisterCompleteStepView(
                    nickname: store.signedUpUser?.nickname ?? store.nickname,
                    interestSummary: interestSummary,
                    hasKeywords: !store.keywords.isEmpty,
                    onStart: { store.send(.startTapped) }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .complete, in: geo.size.width))
                .stepInteraction(isCurrent: store.currentStep == .complete)
            }
            // 뒤로 가기, 닉네임 중복으로 돌아가기, 가입 완료처럼 버튼 밖에서 단계가 바뀌어도 같은 속도로 밀린다.
            .animation(.easeInOut(duration: 0.3), value: store.currentStep)
        }
        .clipped()
    }

    /// 완료 카드 1번 설명. 고른 카테고리 이름과 키워드를 고른 순서대로 " · "로 잇는다.
    private var interestSummary: String {
        let categoryNames = store.selectedCategories.compactMap { id in
            store.recommendList.first { $0.id == id }?.recommendName
        }
        return (categoryNames + store.keywords).joined(separator: " · ")
    }

    private func offset(for route: RegisterRoute, in width: CGFloat) -> CGFloat {
        let diff = route.index - store.currentStep.index
        return CGFloat(diff) * width
    }
}

private struct NicknameSettingStepView: View {
    @Binding var nickname: String

    let validationState: NicknameValidationState
    let errorMessage: String?
    let isSubmitting: Bool
    /// 추천 닉네임을 받는 중이면 "다음"을 막는다. 응답이 오면 닉네임이 바뀌기 때문이다.
    let isRecommending: Bool
    let onValidate: () -> Void
    let onRecommend: () -> Void
    let onNext: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RegisterTitle(text: "팝팡에서 쓸\n닉네임을 정해주세요")
                .padding(.top, RegisterLayout.titleTop)

            HStack(spacing: 10) {
                nicknameField

                Button(action: onValidate) {
                    Text("확인", bundle: .module, comment: "Button that checks whether the nickname is already taken")
                        .font(Font(UIFont.scdream(.medium, size: 12)))
                        .foregroundStyle(Color.subWhite)
                        .frame(
                            width: RegisterLayout.checkButtonSize.width,
                            height: RegisterLayout.checkButtonSize.height
                        )
                        .background(Color.mainOrange)
                        .clipShape(RoundedRectangle(cornerRadius: RegisterLayout.checkButtonRadius))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isSubmitting)
            }
            .padding(.top, 43)

            nicknameMessage

            recommendButton
                .padding(.top, 16)

            Spacer()

            RegisterNextButton(
                title: String(localized: "다음", bundle: .module),
                isEnabled: validationState == .success && !isRecommending
            ) {
                isFocused = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    onNext()
                }
            }
            .padding(.horizontal, RegisterLayout.buttonHorizontal - RegisterLayout.screenHorizontal)
        }
        .padding(.horizontal, RegisterLayout.screenHorizontal)
    }

    private var nicknameField: some View {
        TextField(
            "",
            text: $nickname,
            prompt: Text("닉네임을 입력해 주세요", bundle: .module)
                .foregroundStyle(Color.mainGray6)
        )
        .font(Font(UIFont.scdream(.medium, size: 17)))
        .foregroundStyle(Color.registerText)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .focused($isFocused)
        .padding(.horizontal, RegisterLayout.fieldPadding)
        .frame(height: RegisterLayout.fieldHeight)
        .background(Color.subWhite)
        .overlay {
            RoundedRectangle(cornerRadius: RegisterLayout.fieldRadius)
                .stroke(Color.mainOrange, lineWidth: 1)
        }
    }

    private var recommendButton: some View {
        Button(action: onRecommend) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text("다른 닉네임 추천받기", bundle: .module, comment: "Button that fills in another random nickname")
                    .font(Font(UIFont.scdream(.bold, size: 13)))
            }
            .foregroundStyle(Color.mainBlack)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Capsule().fill(Color.subWhite3))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isSubmitting)
    }

    @ViewBuilder
    private var nicknameMessage: some View {
        // 입력하다 빈 칸이 되면 안내하지 않는다. 빈 칸에서 "확인"을 누르면(.tooShort) 안내한다.
        if !nickname.isEmpty || validationState == .tooShort, let message = validationMessage {
            HStack(spacing: 4) {
                if validationState == .success {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(message, bundle: .module)
            }
            .ppStyleFont(.scdream(.extraBold, size: 13), lineHeightPt: 15.52)
            .foregroundStyle(validationColor)
            .padding(.top, RegisterLayout.messageTop)
        }

        if let errorMessage {
            Text(errorMessage)
                .ppStyleFont(.scdream(.extraBold, size: 13), lineHeightPt: 15.52)
                .foregroundStyle(Color.mainRed)
                .padding(.top, RegisterLayout.messageTop)
        }
    }

    private var validationMessage: LocalizedStringKey? {
        switch validationState {
        case .success:
            "사용할 수 있는 닉네임이에요"
        case .duplicate:
            "이미 사용 중인 닉네임입니다."
        case .invalidSpace:
            "공백은 사용할 수 없습니다."
        case .tooShort:
            "2글자 이하는 사용할 수 없습니다."
        case .checking:
            "닉네임을 확인 중입니다."
        case .none:
            nil
        }
    }

    private var validationColor: Color {
        switch validationState {
        case .success:
            .registerValid
        case .checking:
            .mainGray
        case .duplicate, .invalidSpace, .tooShort, .none:
            .mainRed
        }
    }
}

private struct CategorySettingStepView: View {
    let recommendList: [Recommend]
    let selectedCategories: [Int]
    let isLoadFailed: Bool
    let onToggle: (Int) -> Void
    let onRetry: () -> Void
    let onNext: () -> Void

    private var isNextEnabled: Bool {
        !selectedCategories.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 카테고리가 많거나 화면이 낮으면(SE) 버튼을 가리지 않게 위쪽만 스크롤한다.
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RegisterTitle(text: "어떤 팝업을\n좋아하세요?")
                        .padding(.top, RegisterLayout.titleTop)

                    RegisterSectionLabel(text: "카테고리")
                        .padding(.top, RegisterLayout.sectionLabelTop)

                    if recommendList.isEmpty, isLoadFailed {
                        loadFailedView
                            .padding(.top, RegisterLayout.chipsTop)
                    } else {
                        RegisterChipFlowLayout {
                            ForEach(recommendList, id: \.id) { category in
                                let isSelected = selectedCategories.contains(category.id)
                                RegisterChip(
                                    text: isSelected ? "✓ \(category.recommendName)" : category.recommendName,
                                    style: isSelected ? .selected : .normal
                                ) {
                                    onToggle(category.id)
                                }
                            }
                        }
                        .padding(.top, RegisterLayout.chipsTop)
                    }
                }
                .padding(.bottom, RegisterLayout.summaryBottom)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            RegisterNextButton(
                title: String(localized: "다음", bundle: .module),
                isEnabled: isNextEnabled
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onNext()
                }
            }
            .padding(.horizontal, RegisterLayout.buttonHorizontal - RegisterLayout.screenHorizontal)
        }
        .padding(.horizontal, RegisterLayout.screenHorizontal)
    }

    /// 카테고리 목록을 받지 못하면 칩 자리에 안내와 "다시 시도"를 보여 준다. 카테고리를 골라야 다음으로 갈 수 있기 때문이다.
    private var loadFailedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AuthErrorMessage.recommendListLoadFailed)
                .ppStyleFont(.scdream(.extraBold, size: 13), lineHeightPt: 15.52)
                .foregroundStyle(Color.mainRed)

            RegisterChip(
                text: String(localized: "다시 시도", bundle: .module, comment: "Button that loads the interest categories again after a failure"),
                style: .normal,
                action: onRetry
            )
        }
    }
}

private struct KeywordSettingStepView: View {
    @Binding var text: String

    let keywords: [String]
    let popularKeywords: [String]
    let isSubmitting: Bool
    let errorMessage: String?
    let onAddKeyword: (String) -> Void
    let onAddPopularKeyword: (String) -> Void
    let onRemoveKeyword: (Int) -> Void
    @Binding var isLimitAlertPresented: Bool
    let onSkip: () -> Void
    let onNext: () -> Void

    /// 가입하러 넘어갈 때 키보드를 내린다. 남아 있으면 완료 화면의 "시작하기"를 가린다.
    @FocusState private var isKeywordFocused: Bool

    private var isNextEnabled: Bool { !keywords.isEmpty }
    private var maxCount: Int { RegisterFlowFeature.maxKeywordCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 키보드가 올라오거나 화면이 낮으면(SE) 버튼을 가리지 않게 위쪽만 스크롤한다.
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        RegisterTitle(text: "알림 받을 키워드를\n등록해주세요")

                        Button {
                            isKeywordFocused = false
                            onSkip()
                        } label: {
                            Text("건너뛰기", bundle: .module)
                                .ppStyleFont(.scdream(.medium, size: 14), lineHeightPt: 17)
                                .foregroundStyle(Color.onboardingGray)
                                .padding(.top, 2)
                        }
                        .disabled(isSubmitting)
                    }
                    .padding(.top, RegisterLayout.titleTop)

                    Text("브랜드나 캐릭터 이름이면 더 정확해요.", bundle: .module)
                        .ppStyleFont(.scdream(.regular, size: 14), lineHeightPt: 20.6)
                        .foregroundStyle(Color.onboardingBody)
                        .padding(.top, RegisterLayout.subtitleTop)

                    HStack(spacing: RegisterLayout.chipSpacing) {
                        keywordField

                        Button {
                            add(text, clearsInput: true)
                        } label: {
                            Text("추가", bundle: .module, comment: "Button that adds the typed keyword")
                                .font(Font(UIFont.scdream(.extraBold, size: 15)))
                                .foregroundStyle(Color.subWhite)
                                .frame(width: RegisterLayout.addButtonWidth, height: RegisterLayout.keywordFieldHeight)
                                .background(Color.registerText)
                                .clipShape(RoundedRectangle(cornerRadius: RegisterLayout.fieldRadius))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.top, RegisterLayout.keywordFieldTop)

                    HStack {
                        RegisterSectionLabel(text: "내 키워드")
                        Spacer()
                        Text(verbatim: "\(keywords.count) / \(maxCount)")
                            .ppStyleFont(.scdream(.extraBold, size: 14), lineHeightPt: 17)
                            .foregroundStyle(Color.mainOrange)
                    }
                    .padding(.top, RegisterLayout.myKeywordLabelTop)

                    if !keywords.isEmpty {
                        RegisterChipFlowLayout {
                            ForEach(Array(keywords.enumerated()), id: \.element) { index, keyword in
                                RegisterChip(text: "\(keyword)  ×", style: .added) {
                                    onRemoveKeyword(index)
                                }
                                .accessibilityLabel(Text("\(keyword) 삭제", bundle: .module, comment: "Accessibility label for removing a keyword chip"))
                            }
                        }
                        .padding(.top, RegisterLayout.myKeywordChipsTop)
                    }

                    if !popularKeywords.isEmpty {
                        RegisterSectionLabel(text: "많이 등록한 키워드")
                            .padding(.top, RegisterLayout.popularLabelTop)

                        RegisterChipFlowLayout {
                            ForEach(popularKeywords, id: \.self) { keyword in
                                RegisterChip(text: "+ \(keyword)", style: .normal) {
                                    add(keyword, clearsInput: false)
                                }
                                .accessibilityLabel(Text("\(keyword) 추가", bundle: .module, comment: "Accessibility label for adding a popular keyword"))
                            }
                        }
                        .padding(.top, RegisterLayout.popularChipsTop)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .ppStyleFont(.scdream(.extraBold, size: 13), lineHeightPt: 15.52)
                            .foregroundStyle(Color.mainRed)
                            .padding(.top, RegisterLayout.messageTop)
                    }
                }
                .padding(.bottom, RegisterLayout.summaryBottom)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

            RegisterNextButton(
                title: isSubmitting
                    ? String(localized: "가입 중...", bundle: .module)
                    : String(localized: "다음", bundle: .module),
                isEnabled: isNextEnabled && !isSubmitting
            ) {
                isKeywordFocused = false
                onNext()
            }
            .padding(.horizontal, RegisterLayout.buttonHorizontal - RegisterLayout.screenHorizontal)
        }
        .padding(.horizontal, RegisterLayout.screenHorizontal)
        .alert(Text("키워드 개수 제한", bundle: .module), isPresented: $isLimitAlertPresented) {
            Button(String(localized: "확인", bundle: .module), role: .cancel) {}
        } message: {
            Text("키워드는 최대 \(maxCount)개 까지만 등록 가능합니다.", bundle: .module, comment: "Alert message when adding more keywords than the limit. The argument is the limit")
        }
    }

    private var keywordField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.mainGray6)

            TextField(
                "",
                text: $text,
                prompt: Text("예: 두쫀쿠, 짱구, 레고", bundle: .module, comment: "Placeholder for the keyword field")
                    .foregroundStyle(Color.mainGray6)
            )
            .font(Font(UIFont.scdream(.light, size: 15)))
            .foregroundStyle(Color.registerText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($isKeywordFocused)
            .onSubmit {
                add(text, clearsInput: true)
            }
        }
        .padding(.horizontal, RegisterLayout.fieldPadding)
        .frame(height: RegisterLayout.keywordFieldHeight)
        .background(Color.subWhite3)
        .clipShape(RoundedRectangle(cornerRadius: RegisterLayout.fieldRadius))
    }

    /// 빈 칸·중복·5개 제한은 reducer가 판단한다. 5개를 넘으면 reducer가 제한 알림을 띄운다.
    private func add(_ keyword: String, clearsInput: Bool) {
        if clearsInput {
            onAddKeyword(keyword)
        } else {
            onAddPopularKeyword(keyword)
        }
    }
}

private extension View {
    /// 옆으로 밀려 안 보이는 단계는 터치와 VoiceOver에서 뺀다. 숨은 단계의 버튼이 눌리지 않게 한다.
    func stepInteraction(isCurrent: Bool) -> some View {
        allowsHitTesting(isCurrent)
            .accessibilityHidden(!isCurrent)
    }
}
