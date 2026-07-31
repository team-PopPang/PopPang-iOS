import ComposableArchitecture
import Core
import Foundation

struct PopupPaginationItem: Equatable, Identifiable, Sendable {
    let popupUuid: String
    let thumbnailUrl: String?
    let region: String
    let name: String
    let startDate: String
    let endDate: String
    let isFavorited: Bool

    var id: String { popupUuid }

    var thumbnailURL: URL? {
        guard let thumbnailUrl, !thumbnailUrl.isEmpty else { return nil }

        if let absoluteURL = URL(string: thumbnailUrl), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return NetworkConfig.imageBaseURL.appendingPathComponent(
            thumbnailUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )
    }
}

struct PopupPaginationPage: Equatable, Sendable {
    let items: [PopupPaginationItem]
    let hasNext: Bool
    let nextCursor: Int64?
}

struct PopupPaginationClient: Sendable {
    var fetchPage: @Sendable (
        _ userUuid: String,
        _ cursor: Int64?
    ) async throws -> PopupPaginationPage
}

extension PopupPaginationClient: DependencyKey {
    static let liveValue = Self { userUuid, cursor in
        let endpoint = NetworkConfig.apiBaseURL
            .appendingPathComponent("users")
            .appendingPathComponent(userUuid)
            .appendingPathComponent("popups")
            .appendingPathComponent("scroll")

        guard var components = URLComponents(
            url: endpoint,
            resolvingAgainstBaseURL: false
        ) else {
            throw PopupPaginationClientError.invalidURL
        }

        if let cursor {
            components.queryItems = [
                URLQueryItem(name: "cursor", value: String(cursor)),
            ]
        }

        guard let url = components.url else {
            throw PopupPaginationClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PopupPaginationClientError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw PopupPaginationClientError.server(statusCode: httpResponse.statusCode)
        }

        let responseDTO = try JSONDecoder().decode(
            PopupPaginationResponseDTO.self,
            from: data
        )

        return responseDTO.toModel()
    }
}

extension DependencyValues {
    var popupPaginationClient: PopupPaginationClient {
        get { self[PopupPaginationClient.self] }
        set { self[PopupPaginationClient.self] = newValue }
    }
}

private struct PopupPaginationResponseDTO: Decodable {
    let items: [PopupPaginationItemDTO]
    let hasNext: Bool
    let nextCursor: Int64?

    func toModel() -> PopupPaginationPage {
        PopupPaginationPage(
            items: items.map { $0.toModel() },
            hasNext: hasNext,
            nextCursor: nextCursor
        )
    }
}

private struct PopupPaginationItemDTO: Decodable {
    let popupUuid: String
    let thumbnailUrl: String?
    let region: String
    let name: String
    let startDate: String
    let endDate: String
    let isFavorited: Bool

    func toModel() -> PopupPaginationItem {
        PopupPaginationItem(
            popupUuid: popupUuid,
            thumbnailUrl: thumbnailUrl,
            region: region,
            name: name,
            startDate: startDate,
            endDate: endDate,
            isFavorited: isFavorited
        )
    }
}

private enum PopupPaginationClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "요청 URL을 만들 수 없습니다."
        case .invalidResponse:
            "서버 응답을 확인할 수 없습니다."
        case .server(let statusCode):
            "서버 요청에 실패했습니다. (HTTP \(statusCode))"
        }
    }
}
