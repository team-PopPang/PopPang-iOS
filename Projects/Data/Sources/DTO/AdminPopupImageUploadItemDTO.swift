import Foundation
import Moya

public struct AdminPopupImageUploadItemDTO: Sendable {
    public let data: Data
    public let formName: String
    public let fileName: String
    public let mimeType: String

    public init(
        data: Data,
        formName: String,
        fileName: String,
        mimeType: String
    ) {
        self.data = data
        self.formName = formName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

public extension AdminPopupImageUploadItemDTO {
    func toMultipartFormData() -> MultipartFormData {
        MultipartFormData(
            provider: .data(data),
            name: formName,
            fileName: fileName,
            mimeType: mimeType
        )
    }
}
