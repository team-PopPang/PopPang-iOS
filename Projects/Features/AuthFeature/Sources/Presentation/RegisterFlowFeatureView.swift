import Domain
import DSKit
import SwiftUI
import UIKit

public struct RegisterFlowFeatureView: View {
    private let initialUser: User?
    private let checkNickname: (@MainActor (String) async throws -> Bool)?
    private let register: (@MainActor (User) async throws -> User)?
    private let onComplete: (User) -> Void

    @State private var currentStep: RegisterRoute = .nickname
    @State private var isForward = true
    @State private var nickname = ""
    @State private var validationState: NicknameValidationState = .none
    @State private var keywords: [String] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    public init(
        user: User?,
        checkNickname: (@MainActor (String) async throws -> Bool)? = nil,
        register: (@MainActor (User) async throws -> User)? = nil,
        onComplete: @escaping (User) -> Void = { _ in }
    ) {
        self.initialUser = user
        self.checkNickname = checkNickname
        self.register = register
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
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

                    Button {
                        withAnimation(.easeOut) {
                            if currentStep == .keyword {
                                completeRegistration()
                            }
                        }
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
            .background(Color.white)

            ProgressView(
                value: Double(currentStep.index + 1),
                total: Double(RegisterRoute.allCases.count)
            )
            .progressViewStyle(.linear)
            .tint(.orange)
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            GeometryReader { geo in
                ZStack {
                    NicknameSettingStepView(
                        nickname: $nickname,
                        validationState: $validationState,
                        errorMessage: $errorMessage,
                        isSubmitting: $isSubmitting,
                        checkNickname: checkNickname,
                        onNext: {
                            withAnimation(.easeInOut) {
                                isForward = true
                                currentStep = .keyword
                            }
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: offset(for: .nickname, in: geo.size.width))

                    KeywordSettingStepView(
                        keywords: $keywords,
                        isSubmitting: $isSubmitting,
                        errorMessage: $errorMessage,
                        onNext: completeRegistration
                    )
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
        case .keyword:
            currentStep = .nickname
        default:
            break
        }
    }

    private func offset(for route: RegisterRoute, in width: CGFloat) -> CGFloat {
        let diff = route.index - currentStep.index
        return CGFloat(diff) * width
    }

    private func completeRegistration() {
        guard !isSubmitting else { return }

        var user = initialUser ?? User(
            userUuid: UUID().uuidString,
            uid: UUID().uuidString,
            provider: "KAKAO",
            email: nil,
            nickname: nil,
            role: "USER",
            isAlerted: false,
            fcmToken: nil,
            alertKeywordList: nil,
            recommendList: nil
        )
        user.nickname = nickname
        user.alertKeywordList = keywords
        user.isAlerted = !keywords.isEmpty

        isSubmitting = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let registeredUser: User
                if let register {
                    registeredUser = try await register(user)
                } else {
                    registeredUser = user
                }
                isSubmitting = false
                onComplete(registeredUser)
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private enum RegisterRoute: Int, CaseIterable, Hashable {
    case nickname = 0
    case keyword

    var index: Int { rawValue }
}

private struct NicknameSettingStepView: View {
    @Binding var nickname: String
    @Binding var validationState: NicknameValidationState
    @Binding var errorMessage: String?
    @Binding var isSubmitting: Bool

    let checkNickname: (@MainActor (String) async throws -> Bool)?
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
                .onChange(of: nickname) { _, newValue in
                    if newValue.contains(" ") {
                        validationState = .invalidSpace
                    } else if newValue.count <= 2 {
                        validationState = newValue.isEmpty ? .none : .tooShort
                    } else {
                        validationState = .none
                    }
                }

                Button {
                    validateNickname()
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
                UIApplication.shared.endEditing()
                Task {
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onNext()
                    }
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
            default:
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

    private func validateNickname() {
        guard !nickname.contains(" ") else {
            validationState = .invalidSpace
            return
        }
        guard nickname.count > 2 else {
            validationState = .tooShort
            return
        }

        isSubmitting = true
        validationState = .checking
        errorMessage = nil

        Task { @MainActor in
            do {
                let isDuplicated: Bool
                if let checkNickname {
                    isDuplicated = try await checkNickname(nickname)
                } else {
                    isDuplicated = false
                }
                validationState = isDuplicated ? .duplicate : .success
                isSubmitting = false
            } catch {
                validationState = .none
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

private struct KeywordSettingStepView: View {
    @Binding var keywords: [String]
    @Binding var isSubmitting: Bool
    @Binding var errorMessage: String?

    let onNext: () -> Void

    @State private var text = ""
    private let maxKeywordCount = 5
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
                    addKeyword()
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
                            keywords.remove(at: index)
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
    }

    private func addKeyword() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard keywords.count < maxKeywordCount else { return }
        guard !keywords.contains(trimmed) else { return }

        keywords.append(trimmed)
        text = ""
    }
}

private extension UIApplication {
    func endEditing() {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .endEditing(true)
    }
}
