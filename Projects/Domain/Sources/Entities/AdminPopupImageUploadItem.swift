import Foundation

public struct AdminPopupImageUploadItem: Sendable {
    public let data: Data
    public let formName: String
    public let fileName: String
    public let mimeType: String

    public init(
        data: Data,
        formName: String = "images",
        fileName: String,
        mimeType: String
    ) {
        self.data = data
        self.formName = formName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
