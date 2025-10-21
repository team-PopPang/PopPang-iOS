//
//  PopupDTO.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import Foundation

struct PopupDTO: Decodable {
    let popupUuid: String
    let name: String
    let startDate: String
    let endDate: String
    let openTime: String?
    let closeTime: String?
    let address: String
    let roadAddress: String
    let region: String
    let latitude: Double?
    let longitude: Double?
    let instaPostId: String
    let instaPostUrl: String
    let captionSummary: String
    let imageUrlList: [String]
    let mediaType: String
}

extension PopupDTO {
    func toEntity() -> Popup {
        
        // MARK: - 이미지 경로에 baseURL이 없으면 추가하겠다
        let fullImageUrlList = imageUrlList.map { url in
            if url.hasPrefix("http") {
                return url
            } else {
                return Constants.PopPangAPI.apiURL + url
            }
        }
        
        return Popup(
            popupUuid: popupUuid,
            name: name,
            startDate: DateFormatter.popupDateFormat.date(from: startDate) ?? Date(),
            endDate: DateFormatter.popupDateFormat.date(from: endDate) ?? Date(),
            openTime: DateFormatter.serverTimeFormat.date(from: openTime ?? "") ?? Date(),
            closeTime: DateFormatter.serverTimeFormat.date(from: closeTime ?? "") ?? Date(),
            address: address,
            roadAddress: roadAddress,
            region: region,
            latitude: latitude,
            longitude: longitude,
            instaPostId: instaPostId,
            instaPostUrl: instaPostUrl,
            captionSummary: captionSummary,
            imageUrlList: fullImageUrlList,
            mediaType: Popup.MediaType(rawValue: mediaType.uppercased()) ?? .image
            )
    }
}
