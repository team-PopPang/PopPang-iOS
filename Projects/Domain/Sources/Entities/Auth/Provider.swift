/// 소셜 로그인 제공자
public enum Provider: String, CaseIterable, Equatable, Sendable {
    case kakao = "KAKAO"
    case apple = "APPLE"
    case google = "GOOGLE"
}
