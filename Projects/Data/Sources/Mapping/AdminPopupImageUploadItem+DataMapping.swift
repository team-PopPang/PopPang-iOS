import Domain

extension AdminPopupImageUploadItem {
    func toDTO() -> AdminPopupImageUploadItemDTO {
        AdminPopupImageUploadItemDTO(
            data: data,
            formName: formName,
            fileName: fileName,
            mimeType: mimeType
        )
    }
}
