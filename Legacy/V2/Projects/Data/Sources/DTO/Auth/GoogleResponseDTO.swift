import Foundation

public struct GoogleResponseDTO: Sendable {
    public var oauthId: String = ""
    public var idToken: String = ""

    public init(oauthId: String = "", idToken: String = "") {
        self.oauthId = oauthId
        self.idToken = idToken
    }
}
