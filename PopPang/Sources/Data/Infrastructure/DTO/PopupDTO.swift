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
    let roadAddress: String?
    let region: String
    let latitude: Double?
    let longitude: Double?
    // let geocodingQuery: String 일단 임시로 뻄
    let instaPostId: String
    let instaPostUrl: String
    // let like: String: 일단 임시로 뻄
    let captionSummary: String
    let caption: String
    let imageUrl: String
    let mediaType: String
    let errorCode: String?
}

extension PopupDTO {
    func toEntity() -> Popup {
        
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
            instaPostURL: instaPostUrl,
            captionSummary: captionSummary,
            caption: caption,
            imageURL: imageUrl,
            mediaType: Popup.MediaType(rawValue: mediaType.uppercased()) ?? .image,
            errorCode: errorCode)
    }
}
