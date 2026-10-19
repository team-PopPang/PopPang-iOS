import Foundation

/// V2 API 가운데 성공 응답을 감싸서 주는 API의 응답 형식.
///
/// V2라도 API마다 감싸는지가 다르다. 모든 응답에 일괄 적용하지 않고,
/// 감싸는 API에서만 `asyncRequest(_:decodeDataTo:)`로 디코딩한다.
public struct APIResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let code: Int
    public let message: String
    public let data: T
}

/// 실패 응답 형식. V1과 V2가 같다.
public struct ErrorResponse: Decodable, Equatable, Sendable {
    public let success: Bool
    public let code: Int
    public let message: String
}
