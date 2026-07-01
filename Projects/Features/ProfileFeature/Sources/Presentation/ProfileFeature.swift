import ComposableArchitecture
import Core
import DSKit
import Foundation

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
        public var isLoading = false
        public var errorMessage: String?
        public var localIsAlerted: Bool

        public init(session: Shared<UserSession>) {
            self._session = session
            self.localIsAlerted = session.wrappedValue.context?.isAlerted ?? false
        }

        public var userUuid: String {
            sessionContext.userUuid
        }

        public var nickname: String {
            sessionContext.nickname
        }

        var sessionContext: SessionContext {
            guard let context = session.context else {
                preconditionFailure("ProfileFeature requires a logged in session.")
            }
            return context
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.nickname == rhs.nickname
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
        case alertStatusResponse(Result<Void, Error>, Bool)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case profileSettingRequested
            case notificationsRequested
            case serviceTermsRequested
        }
    }

    @Dependencies.Dependency(\.profileFeatureClient) private var profileFeatureClient: ProfileFeatureClient

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
                let userUuid = state.userUuid

                return .run { [profileFeatureClient] send in
                    do {
                        try await profileFeatureClient.alertStatus(userUuid, isAlerted)
                        await send(.alertStatusResponse(.success(()), isAlerted))
                    } catch {
                        await send(.alertStatusResponse(.failure(error), previousValue))
                    }
                }

            case .alertStatusResponse(.success, let resolvedValue):
                state.isLoading = false
                state.localIsAlerted = resolvedValue
                state.errorMessage = nil
                state.$session.withLock { $0.user?.isAlerted = resolvedValue }
                return .none

            case .alertStatusResponse(.failure(let error), let resolvedValue):
                state.isLoading = false
                state.localIsAlerted = resolvedValue
                state.errorMessage = error.localizedDescription
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
        @Shared var session: UserSession
        public var newNickname = ""
        public var validationState: NicknameValidationState = .none
        public var isLoading = false
        public var errorMessage: String?

        public init(session: Shared<UserSession>) {
            self._session = session
        }

        public var userUuid: String {
            sessionContext.userUuid
        }

        public var nickname: String {
            sessionContext.nickname
        }

        var sessionContext: SessionContext {
            guard let context = session.context else {
                preconditionFailure("ProfileSettingFeature requires a logged in session.")
            }
            return context
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.nickname == rhs.nickname
                && lhs.newNickname == rhs.newNickname
                && lhs.validationState == rhs.validationState
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case backTapped
        case nicknameChanged(String)
        case validateNicknameTapped
        case validateNicknameResponse(Result<Bool, Error>)
        case updateNicknameTapped
        case updateNicknameResponse(Result<Void, Error>)
        case logoutTapped
        case hardDeleteTapped
        case hardDeleteResponse(Result<Void, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
            case logoutRequested
        }
    }

    @Dependencies.Dependency(\.profileFeatureClient) private var profileFeatureClient: ProfileFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.dismiss))

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
                        await send(.validateNicknameResponse(.success(isDuplicated)))
                    } catch {
                        await send(.validateNicknameResponse(.failure(error)))
                    }
                }

            case .validateNicknameResponse(.success(let isDuplicated)):
                state.isLoading = false
                state.validationState = isDuplicated ? .duplicate : .success
                return .none

            case .validateNicknameResponse(.failure(let error)):
                state.isLoading = false
                state.validationState = .none
                state.errorMessage = error.localizedDescription
                return .none

            case .updateNicknameTapped:
                guard state.validationState == .success else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let userUuid = state.userUuid
                let nickname = state.newNickname

                return .run { [profileFeatureClient] send in
                    do {
                        try await profileFeatureClient.updateNickname(userUuid, nickname)
                        await send(.updateNicknameResponse(.success(())))
                    } catch {
                        await send(.updateNicknameResponse(.failure(error)))
                    }
                }

            case .updateNicknameResponse(.success):
                state.isLoading = false
                state.errorMessage = nil
                let nickname = state.newNickname
                state.$session.withLock { $0.user?.nickname = nickname }
                return .send(.delegate(.dismiss))

            case .updateNicknameResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .logoutTapped:
                return .send(.delegate(.logoutRequested))

            case .hardDeleteTapped:
                state.isLoading = true
                state.errorMessage = nil
                let userUuid = state.userUuid

                return .run { [profileFeatureClient] send in
                    do {
                        try await profileFeatureClient.hardDeleteUser(userUuid)
                        await send(.hardDeleteResponse(.success(())))
                    } catch {
                        await send(.hardDeleteResponse(.failure(error)))
                    }
                }

            case .hardDeleteResponse(.success):
                state.isLoading = false
                return .send(.delegate(.logoutRequested))

            case .hardDeleteResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
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
