import Foundation

/// 가입 화면의 인기 키워드 항목 (`GET /api/v2/alert-keyword/popular`)
public struct PopularAlertKeywordDTO: Decodable, Sendable {
    public let alertKeyword: String

    public init(alertKeyword: String) {
        self.alertKeyword = alertKeyword
    }
}
