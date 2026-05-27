import Compound
import Domain
import DSKit
import Foundation

@Compound
final class ProfileFeatureCompound {
    enum Action {
        case onAppear
        case nicknameChanged(String)
        case checkNewNickname
        case updateNewNickname
        case hardDeleteUser
        case alertStatus(Bool)
        case clearNickname
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setDidPreload(Bool)
        case setLoading(Bool)
        case setNickname(String)
        case setNewNickname(String)
        case setValidationState(NicknameValidationState)
        case setAlerted(Bool)
        case setErrorMessage(String?)
        case setDeleteCompleted(Bool)
        case setNicknameUpdated(Bool)
    }

    struct State: Equatable {
        var userUuid: String
        var nickname: String
        var isAlerted: Bool
        var newNickname = ""
        var validationState: NicknameValidationState = .none
        var isLoading = false
        var errorMessage: String?
        var didDeleteUser = false
        var didUpdateNickname = false
        var didPreload = false
    }

    var state: State

    @Dependency private var userUsecase: UserUsecaseProtocol

    init(
        userUuid: String,
        nickname: String,
        isAlerted: Bool
    ) {
        self.state = State(
            userUuid: userUuid,
            nickname: nickname,
            isAlerted: isAlerted
        )
    }

    @MainActor
    func preload() {
        send(.onAppear)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            guard !state.didPreload else { return Self.emptyReactionStream() }

            return .concat(
                .just(.setDidPreload(true)),
                .just(.setLoading(false))
            )

        case .nicknameChanged(let nickname):
            return .concat(
                .just(.setNewNickname(nickname)),
                .just(.setValidationState(Self.localValidationState(for: nickname)))
            )

        case .checkNewNickname:
            guard !state.newNickname.isEmpty else { return Self.emptyReactionStream() }
            switch state.validationState {
            case .invalidSpace, .tooShort:
                return Self.emptyReactionStream()
            default:
                return checkNickname()
            }

        case .updateNewNickname:
            return updateNickname()

        case .hardDeleteUser:
            return hardDeleteUser()

        case .alertStatus(let isAlerted):
            return updateAlertStatus(isAlerted: isAlerted)

        case .clearNickname:
            return .concat(
                .just(.setNewNickname("")),
                .just(.setValidationState(.none)),
                .just(.setNicknameUpdated(false))
            )

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setDidPreload(let didPreload):
            newState.didPreload = didPreload
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setNickname(let nickname):
            newState.nickname = nickname
        case .setNewNickname(let nickname):
            newState.newNickname = nickname
        case .setValidationState(let validationState):
            newState.validationState = validationState
        case .setAlerted(let isAlerted):
            newState.isAlerted = isAlerted
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        case .setDeleteCompleted(let isCompleted):
            newState.didDeleteUser = isCompleted
        case .setNicknameUpdated(let isUpdated):
            newState.didUpdateNickname = isUpdated
        }

        return newState
    }
}

private extension ProfileFeatureCompound {
    func checkNickname() -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setValidationState(.checking)),
            .just(.setErrorMessage(nil)),
            .run { [state, userUsecase] send in
                do {
                    let isDuplicated = try await userUsecase.checkNickname(nickname: state.newNickname)
                    await send(.setValidationState(isDuplicated ? .duplicate : .success))
                } catch {
                    await send(.setValidationState(.none))
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func updateNickname() -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [state, userUsecase] send in
                do {
                    try await userUsecase.updateNickname(
                        userUuid: state.userUuid,
                        newNickname: state.newNickname
                    )
                    await send(.setNickname(state.newNickname))
                    await send(.setNicknameUpdated(true))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func hardDeleteUser() -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [state, userUsecase] send in
                do {
                    try await userUsecase.hardDeleteUser(userUuid: state.userUuid)
                    await send(.setDeleteCompleted(true))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func updateAlertStatus(isAlerted: Bool) -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.setAlerted(isAlerted)),
            .run { [state, userUsecase] send in
                do {
                    try await userUsecase.alertStatus(
                        userUuid: state.userUuid,
                        isAlerted: isAlerted
                    )
                    await send(.setErrorMessage(nil))
                } catch {
                    await send(.setAlerted(state.isAlerted))
                    await send(.setErrorMessage(error.localizedDescription))
                }
            }
        )
    }

    static func localValidationState(for nickname: String) -> NicknameValidationState {
        guard !nickname.isEmpty else { return .none }
        if nickname.contains(" ") { return .invalidSpace }
        if nickname.count <= 2 { return .tooShort }
        return .none
    }

    static func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
