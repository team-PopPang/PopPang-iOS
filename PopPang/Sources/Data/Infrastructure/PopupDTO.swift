//
//  PopupDTO.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import Foundation

struct PopupDTO {
    let name: String
    let startDate: String
    let endDate: String
    let openTime: String
    let closeTime: String
    let address: String
    let region: String
    let instaPostId: String
    let instaPostURL: String
    let likeCount: Int
    let captionSummary: String
    let caption: String
    let imageURL: String
    let mediaType: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case openTime = "open_time"
        case closeTime = "close_time"
        case address
        case region
        case instaPostId = "insta_post_id"
        case instaPostURL = "insta_post_url"
        case likeCount = "like_count"
        case captionSummary = "caption_summary"
        case caption
        case imageURL = "image_url"
        case mediaType = "media_type"
    }
}
