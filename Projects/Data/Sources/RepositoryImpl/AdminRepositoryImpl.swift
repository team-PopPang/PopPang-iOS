import Core
import Domain
import Foundation
import Moya

public final class AdminRepositoryImpl: AdminRepositoryProtocol {
    private let makeV2Provider: () -> MoyaProvider<V2AdminAPI>

    public init(
        makeV2Provider: @escaping () -> MoyaProvider<V2AdminAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
        self.makeV2Provider = makeV2Provider
    }

    public func deactivatePopup(popupUuid: String) async throws {
        do {
            try await makeV2Provider().asyncRequestVoid(.deactivatePopup(popupUuid: popupUuid))
        } catch let error as AuthSessionError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // 화면에는 PopupError로 알리지만 원인을 찾을 수 있게 상태 코드와 서버 코드만 남긴다.
            let description: String
            if let error = error as? NetworkError {
                description = "HTTP \(error.statusCode), code \(error.serverErrorCode.map(String.init) ?? "없음")"
            } else {
                description = String(describing: type(of: error))
            }
            Logger.e("팝업 비활성화 실패: \(description)")
            throw PopupError.failed
        }
    }
}
