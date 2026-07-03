import ComposableArchitecture
import Domain
import DSKit
import SwiftUI
import UserNotifications

public struct RegisterFlowFeatureView: View {
    let store: StoreOf<RegisterFlowFeature>

    public init(store: StoreOf<RegisterFlowFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            progress
            stepPages
        }
        .task {
            store.send(.onAppear)
        }
    }

    private var header: some View {
        HStack {
            if store.currentStep != .nickname {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.black)
                        .padding()
                }

                Spacer()

                Button {
                    store.send(.skipTapped)
                } label: {
                    Text("건너뛰기")
                        .ppStyleFont(.scdream(.regular, size: 13))
                        .foregroundStyle(Color.mainGray)
                        .padding()
                }
            } else {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
                    .padding()
                Spacer()
            }
        }
        .frame(height: 44)
        .background(Color(uiColor: .white))
    }

    private var progress: some View {
        ProgressView(
            value: Double(store.currentStep.index + 1),
            total: Double(RegisterRoute.allCases.count)
        )
        .progressViewStyle(.linear)
        .tint(.orange)
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.3), value: store.currentStep)
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
                    onValidate: {
                        store.send(.validateNicknameTapped)
                    },
                    onNext: {
                        store.send(.nextFromNicknameTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .nickname, in: geo.size.width))

                CategorySettingStepView(
                    recommendList: store.recommendList,
                    selectedCategories: store.selectedCategories,
                    onToggle: { store.send(.categoryToggled($0)) },
                    onNext: {
                        store.send(.nextFromCategoryTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .category, in: geo.size.width))

                KeywordSettingStepView(
                    text: Binding(
                        get: { store.keywordInput },
                        set: { store.send(.keywordInputChanged($0)) }
                    ),
                    keywords: store.keywords,
                    isSubmitting: store.isSubmitting,
                    errorMessage: store.errorMessage,
                    onAddKeyword: { store.send(.keywordAdded($0)) },
                    onRemoveKeyword: { store.send(.keywordRemoved($0)) },
                    onNext: {
                        store.send(.completeRegistrationTapped)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: offset(for: .keyword, in: geo.size.width))
            }
        }
        .clipped()
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
    let onValidate: () -> Void
    let onNext: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("닉네임을\n설정해주세요.")
                        .font(.scdream(.bold, size: 17))
                    Text("닉네임은 나중에 변경할 수 있습니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                Spacer()
            }
            .padding(.top, 50)

            HStack(spacing: 10) {
                RoundedTextField(
                    placeholder: "닉네임을 입력해 주세요",
                    text: $nickname,
                    validationState: validationState
                )
                .focused($isFocused)

                Button {
                    onValidate()
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100)
                        .frame(height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isSubmitting)
            }
            .padding(.top, 20)

            nicknameMessage

            Spacer()

            MainOrangeButton(
                buttonTitle: "다음",
                buttonColor: validationState == .success ? Color.mainOrange : Color.mainGray2
            ) {
                isFocused = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    onNext()
                }
            }
            .disabled(validationState != .success)
            .opacity(validationState == .success ? 1.0 : 0.8)
            .background()
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.horizontal, .contentPadding)
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            isFocused = true
        }
    }

    @ViewBuilder
    private var nicknameMessage: some View {
        if !nickname.isEmpty {
            switch validationState {
            case .success:
                Text("사용 가능한 닉네임입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGreen)
                    .padding(.top, 5)
            case .duplicate:
                Text("이미 사용 중인 닉네임입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .invalidSpace:
                Text("공백은 사용할 수 없습니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .tooShort:
                Text("2글자 이하는 사용할 수 없습니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            case .checking:
                Text("닉네임을 확인 중입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .padding(.top, 5)
            case .none:
                EmptyView()
            }
        }

        if let errorMessage {
            Text(errorMessage)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainRed)
                .padding(.top, 5)
        }
    }
}

private struct CategorySettingStepView: View {
    let recommendList: [Recommend]
    let selectedCategories: [Int]
    let onToggle: (Int) -> Void
    let onNext: () -> Void

    private var isNextEnabled: Bool {
        !selectedCategories.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("추천 받고 싶은 항목을\n선택해주세요.")
                        .font(.scdream(.bold, size: 17))
                    Text("선택하신 항목에 맞게 추천해드려요")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                Spacer()
            }
            .padding(.top, 50)

            FlowLayout(recommendList, id: \.id) { category in
                CategoryButton(
                    title: category.recommendName,
                    isSelected: selectedCategories.contains(category.id)
                ) {
                    onToggle(category.id)
                }
            }
            .padding(.top, 30)

            Spacer()

            MainOrangeButton(
                buttonTitle: "다음",
                buttonColor: isNextEnabled ? Color.mainOrange : Color.mainGray2
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onNext()
                }
            }
            .disabled(!isNextEnabled)
            .opacity(isNextEnabled ? 1.0 : 0.8)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct KeywordSettingStepView: View {
    @Binding var text: String

    let keywords: [String]
    let isSubmitting: Bool
    let errorMessage: String?
    let onAddKeyword: (String) -> Void
    let onRemoveKeyword: (Int) -> Void
    let onNext: () -> Void

    @State private var showPermissionAlert = false
    @State private var showKeywordLimitAlert = false

    private var isNextEnabled: Bool { !keywords.isEmpty }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("키워드를\n입력해주세요.")
                        .font(.scdream(.bold, size: 17))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("등록된 키워드에 맞춰 알림을 받아볼 수 있어요.")
                            .foregroundStyle(Color.mainGray)
                        Text("(최대 5개 등록 가능)")
                    }
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                }

                Spacer()
            }
            .padding(.top, 50)

            HStack(spacing: 10) {
                KeywordTextField(
                    placeholder: "ex) 화장품, 애니메이션",
                    text: $text
                )

                Button {
                    addKeywordIfAllowed()
                } label: {
                    Text("등록")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 70)
                        .frame(height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 20)

            VStack(spacing: 0) {
                ForEach(Array(keywords.enumerated()), id: \.1) { index, keyword in
                    HStack {
                        Text(keyword)
                        Spacer()
                        Button {
                            onRemoveKeyword(index)
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 10, height: 10)
                                .foregroundStyle(Color.mainGray)
                        }
                    }
                    .padding(.top, 17)
                    .padding(.horizontal, 5)

                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.mainGray7)
                        .padding(.top, 5)
                        .padding(.horizontal, 5)
                }
            }
            .padding(.top, 20)

            if let errorMessage {
                Text(errorMessage)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.top, 5)
            }

            Spacer()

            MainOrangeButton(
                buttonTitle: "다음",
                buttonColor: isNextEnabled ? Color.mainOrange : Color.mainGray2
            ) {
                onNext()
            }
            .disabled(!isNextEnabled || isSubmitting)
            .opacity(isNextEnabled ? 1.0 : 0.8)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
        .alert("알림 허용", isPresented: $showPermissionAlert) {
            Button("설정으로 이동") {
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url)
                else { return }
                UIApplication.shared.open(url)
            }
            Button("다음에 하기", role: .cancel) {}
        } message: {
            Text("팝업스토어 키워드 알림을 받으려면 알림 권한을 허용해 주세요.")
        }
        .alert("키워드 개수 제한", isPresented: $showKeywordLimitAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("키워드는 최대 5개 까지만 등록 가능합니다.")
        }
    }

    private func addKeywordIfAllowed() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard keywords.count < 5 else {
            showKeywordLimitAlert = true
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                DispatchQueue.main.async {
                    showPermissionAlert = true
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            onAddKeyword(trimmed)
                        } else {
                            showPermissionAlert = true
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    onAddKeyword(trimmed)
                }
            @unknown default:
                break
            }
        }
    }
}
