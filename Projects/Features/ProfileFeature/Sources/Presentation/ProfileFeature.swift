import ComposableArchitecture
import Domain
import DSKit
import Foundation

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public var nickname: String
        public var isLoading = false
        public var errorMessage: String?
        public var localIsAlerted: Bool

        public init(user: User) {
            self.nickname = user.nickname ?? String(localized: "닉네임", bundle: .module)
            self.localIsAlerted = user.isAlerted
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.nickname == rhs.nickname
                && lhs.localIsAlerted == rhs.localIsAlerted
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case alertTapped
        case profileSettingTapped
        case notificationsTapped
        case serviceTermsTapped
        case alertStatusChanged(Bool)
        /// 실패하면 `previousValue`로 되돌린다.
        case alertStatusResponse(Result<Bool, Error>, previousValue: Bool)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case alertStatusUpdated(Bool)
            case profileSettingRequested
            case notificationsRequested
            case serviceTermsRequested
        }
    }

    @Dependency(\.profileFeatureClient) private var profileFeatureClient: ProfileFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alertTapped:
                return .send(.delegate(.alertRequested))

            case .profileSettingTapped:
                return .send(.delegate(.profileSettingRequested))

            case .notificationsTapped:
                return .send(.delegate(.notificationsRequested))

            case .serviceTermsTapped:
                return .send(.delegate(.serviceTermsRequested))

            case .alertStatusChanged(let isAlerted):
                let previousValue = state.localIsAlerted
                state.localIsAlerted = isAlerted
                state.isLoading = true
                state.errorMessage = nil
                return .run { [profileFeatureClient] send in
                    do {
                        let savedValue = try await profileFeatureClient.alertStatus(isAlerted)
                        await send(.alertStatusResponse(.success(savedValue), previousValue: previousValue))
                    } catch {
                        await send(.alertStatusResponse(.failure(error), previousValue: previousValue))
                    }
                }

            case .alertStatusResponse(.success(let savedValue), _):
                state.isLoading = false
                state.localIsAlerted = savedValue
                state.errorMessage = nil
                return .send(.delegate(.alertStatusUpdated(savedValue)))

            case .alertStatusResponse(.failure(let error), let previousValue):
                state.isLoading = false
                state.localIsAlerted = previousValue
                state.errorMessage = ProfileErrorMessage.alertStatus(for: error)
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

@Reducer
public struct ProfileSettingFeature {
    @ObservableState
    public struct State: Equatable {
        public var nickname: String
        public var newNickname = ""
        public var validationState: NicknameValidationState = .none
        public var isLoading = false
        public var errorMessage: String?

        public init(user: User) {
            self.nickname = user.nickname ?? String(localized: "닉네임", bundle: .module)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.nickname == rhs.nickname
                && lhs.newNickname == rhs.newNickname
                && lhs.validationState == rhs.validationState
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case nicknameChanged(String)
        case validateNicknameTapped
        /// `nickname`은 확인을 보낸 닉네임이다. 그사이 입력이 바뀌었으면 결과를 쓰지 않는다.
        case validateNicknameResponse(nickname: String, Result<Bool, Error>)
        case updateNicknameTapped
        /// `nickname`은 서버에 보낸 닉네임이다. 성공하면 입력란이 아니라 이 값을 알린다.
        case updateNicknameResponse(nickname: String, Result<Void, Error>)
        case logoutTapped
        case withdrawTapped
        case withdrawResponse(Result<Void, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case nicknameUpdated(String)
            case logoutRequested
        }
    }

    @Dependency(\.profileFeatureClient) private var profileFeatureClient: ProfileFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nicknameChanged(let nickname):
                state.newNickname = nickname
                state.validationState = Self.localValidationState(for: nickname)
                if state.validationState != .checking {
                    state.errorMessage = nil
                }
                return .none

            case .validateNicknameTapped:
                guard !state.newNickname.isEmpty else { return .none }
                guard !state.newNickname.contains(" ") else {
                    state.validationState = .invalidSpace
                    return .none
                }
                guard state.newNickname.count > 2 else {
                    state.validationState = .tooShort
                    return .none
                }

                state.isLoading = true
                state.validationState = .checking
                state.errorMessage = nil
                let nickname = state.newNickname

                return .run { [profileFeatureClient] send in
                    do {
                        let isDuplicated = try await profileFeatureClient.checkNickname(nickname)
                        await send(.validateNicknameResponse(nickname: nickname, .success(isDuplicated)))
                    } catch {
                        await send(.validateNicknameResponse(nickname: nickname, .failure(error)))
                    }
                }

            case .validateNicknameResponse(let nickname, _) where nickname != state.newNickname:
                state.isLoading = false
                return .none

            case .validateNicknameResponse(_, .success(let isDuplicated)):
                state.isLoading = false
                state.validationState = isDuplicated ? .duplicate : .success
                return .none

            case .validateNicknameResponse(_, .failure(let error)):
                state.isLoading = false
                state.validationState = .none
                state.errorMessage = ProfileErrorMessage.nicknameCheck(for: error)
                return .none

            case .updateNicknameTapped:
                guard state.validationState == .success else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let nickname = state.newNickname

                return .run { [profileFeatureClient] send in
                    do {
                        try await profileFeatureClient.updateNickname(nickname)
                        await send(.updateNicknameResponse(nickname: nickname, .success(())))
                    } catch {
                        await send(.updateNicknameResponse(nickname: nickname, .failure(error)))
                    }
                }

            case .updateNicknameResponse(let nickname, .success):
                state.isLoading = false
                state.errorMessage = nil
                return .send(.delegate(.nicknameUpdated(nickname)))

            case .updateNicknameResponse(let nickname, .failure(let error)):
                state.isLoading = false
                // 그사이 입력이 바뀌었으면 새 입력의 확인 상태는 건드리지 않는다.
                switch nickname == state.newNickname ? error as? UserError : nil {
                case .duplicateNickname:
                    // 중복 확인 뒤에 다른 사용자가 같은 닉네임을 먼저 쓴 경우다. 입력란 아래 중복 안내를 보여 주고 다시 확인하게 한다.
                    state.validationState = .duplicate
                case .invalidNickname:
                    // 서버가 받지 않는 닉네임이라 "사용 가능" 표시를 지우고 다시 확인하게 한다.
                    state.validationState = .none
                default:
                    break
                }
                state.errorMessage = ProfileErrorMessage.nicknameUpdate(for: error)
                return .none

            case .logoutTapped:
                return .send(.delegate(.logoutRequested))

            case .withdrawTapped:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                return .run { [profileFeatureClient] send in
                    do {
                        try await profileFeatureClient.withdraw()
                        await send(.withdrawResponse(.success(())))
                    } catch {
                        await send(.withdrawResponse(.failure(error)))
                    }
                }

            case .withdrawResponse(.success):
                state.isLoading = false
                return .send(.delegate(.logoutRequested))

            case .withdrawResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = ProfileErrorMessage.withdraw(for: error)
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension ProfileSettingFeature {
    static func localValidationState(for nickname: String) -> NicknameValidationState {
        guard !nickname.isEmpty else { return .none }
        if nickname.contains(" ") { return .invalidSpace }
        if nickname.count <= 2 { return .tooShort }
        return .none
    }
}
