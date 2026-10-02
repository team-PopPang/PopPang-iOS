import Core
import Domain
import Foundation
import Moya

/// 앱 시작 시 서버 헬스 체크를 요청한다.
///
/// 다른 Repository와 달리 Moya provider 대신 `URLSession`으로 요청한다.
/// - Moya를 거치면 네트워크 오류가 Alamofire 오류로 감싸져 오프라인 여부(`URLError` 코드)를 구분하기 어렵다.
/// - 요청 전체 시간을 `timeoutIntervalForResource`로 정확히 제한한다.
/// 요청 주소와 헤더는 다른 API와 같도록 `ServerHealthAPI`(`BaseAPI`)로 만든다.
public final class ServerHealthRepositoryImpl: ServerHealthRepositoryProtocol {
    private let session: URLSession

    public init(session: URLSession = ServerHealthRepositoryImpl.makeSession()) {
        self.session = session
    }

    public func checkHealth() async -> ServerHealth {
        do {
            var request = try MoyaProvider<ServerHealthAPI>
                .defaultEndpointMapping(for: .getHealth)
                .urlRequest()
            request.timeoutInterval = Self.timeout

            let (data, response) = try await session.data(for: request)

            // 백엔드 명세: 200이 아니면 본문과 관계없이 실패로 본다.
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return .unhealthy
            }

            // 200이어도 본문이 예상 형식과 다르면 디코딩 오류로 실패 처리된다.
            return try JSONDecoder()
                .decode(ServerHealthDTO.self, from: data)
                .toEntity()
        } catch {
            return Self.isOffline(error) ? .offline : .unhealthy
        }
    }
}

extension ServerHealthRepositoryImpl {
    /// 헬스 체크 요청 전체를 기다리는 최대 시간(초)
    static let timeout: TimeInterval = 5

    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }
}

private extension ServerHealthRepositoryImpl {
    /// 기기에 인터넷 연결이 없어서 실패했는지 확인한다.
    static func isOffline(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }

        switch urlError.code {
        case .notConnectedToInternet,
             .dataNotAllowed,
             .internationalRoamingOff:
            return true

        default:
            return false
        }
    }
}
