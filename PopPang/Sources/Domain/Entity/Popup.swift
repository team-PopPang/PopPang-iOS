//
//  Popup.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import Foundation

struct Popup: Hashable {
    let name: String
    let startDate: Date
    let endDate: Date
    let openTime: Date
    let closeTime: Date
    let address: String
    let region: String
    let instaPostId: String
    let instaPostURL: String
    var likeCount: String
    let captionSummary: String
    let caption: String
    let imageURL: String
    let mediaType: MediaType
    
    enum MediaType: String, Codable {
        case image
        case video
    }
}

extension Popup {
    static let popupMock: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return Popup(
            name: "카카오팝업스토어",
            startDate: formatter.date(from: "2025-09-27 10:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-05 22:00") ?? Date(),
            openTime: formatter.date(from: "2025-09-27 10:00") ?? Date(),
            closeTime: formatter.date(from: "2025-09-27 22:00") ?? Date(),
            address: "서울 강남구 테헤란로 123",
            region: "서울",
            instaPostId: "1234567890",
            instaPostURL: "https://instagram.com/p/abc123",
            likeCount: "1200",
            captionSummary: "여기는 새로운 굿즈를 선보이는 카카오팝업스토어입니다.",
            caption: "인스타 게시글 원문",
            imageURL: "https://example.com/image.jpg",
            mediaType: .image
        )
    }()
    
    static let popupMocks: [Popup] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return [
            Popup(
                name: "카카오팝업스토어",
                startDate: formatter.date(from: "2025-09-27 10:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-05 22:00") ?? Date(),
                openTime: formatter.date(from: "2025-09-27 10:00") ?? Date(),
                closeTime: formatter.date(from: "2025-09-27 22:00") ?? Date(),
                address: "서울 강남구 테헤란로 123",
                region: "서울",
                instaPostId: "1234567890",
                instaPostURL: "https://instagram.com/p/abc123",
                likeCount: "1200",
                captionSummary: "여기는 새로운 굿즈를 선보이는 카카오팝업스토어입니다.",
                caption: "인스타 게시글 원문",
                imageURL: "img_0",
                mediaType: .image
            ),
            Popup(
                name: "스타벅스 한정 팝업",
                startDate: formatter.date(from: "2025-10-01 09:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-10 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-01 09:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-01 20:00") ?? Date(),
                address: "서울 마포구 합정동 456",
                region: "서울",
                instaPostId: "0987654321",
                instaPostURL: "https://instagram.com/p/xyz789",
                likeCount: "845",
                captionSummary: "스타벅스 신메뉴 팝업 요약",
                caption: "따뜻한 가을 한정 음료를 즐길 수 있는 스타벅스 팝업스토어입니다.",
                imageURL: "img_1",
                mediaType: .image
            ),
            Popup(
                name: "나이키 한정판 팝업",
                startDate: formatter.date(from: "2025-10-05 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-12 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-05 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-05 21:00") ?? Date(),
                address: "서울 송파구 올림픽로 300",
                region: "서울",
                instaPostId: "2468135790",
                instaPostURL: "https://instagram.com/p/nike123",
                likeCount: "1560",
                captionSummary: "나이키 한정판 신발 팝업 요약",
                caption: "한정판 스니커즈를 직접 체험할 수 있는 나이키 팝업스토어입니다.",
                imageURL: "img_2",
                mediaType: .image
            ),
            Popup(
                name: "레고 체험 팝업",
                startDate: formatter.date(from: "2025-09-29 10:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-15 19:00") ?? Date(),
                openTime: formatter.date(from: "2025-09-29 10:00") ?? Date(),
                closeTime: formatter.date(from: "2025-09-29 19:00") ?? Date(),
                address: "서울 용산구 이태원로 99",
                region: "서울",
                instaPostId: "1122334455",
                instaPostURL: "https://instagram.com/p/lego456",
                likeCount: "430",
                captionSummary: "아이와 함께 즐기는 레고 체험 팝업 요약",
                caption: "가족 단위 방문객을 위한 다양한 레고 체험 프로그램이 준비된 팝업스토어입니다.",
                imageURL: "img_3",
                mediaType: .image
            ),
            Popup(
                name: "올리브영 9월 팝업스토어 총정리",
                startDate: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-20 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-03 21:00") ?? Date(),
                address: "서울 마포구",
                region: "서울",
                instaPostId: "3344556677",
                instaPostURL: "https://instagram.com/p/musinsa888",
                likeCount: "980",
                captionSummary: "무신사 스트리트 브랜드 팝업 요약",
                caption: "신진 디자이너 브랜드들을 모아놓은 무신사 팝업스토어입니다.",
                imageURL: "img_7",
                mediaType: .image
            ),
            Popup(
                name: "무신사 스트리트 팝업",
                startDate: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-20 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-03 21:00") ?? Date(),
                address: "서울 성동구 성수동 88",
                region: "서울",
                instaPostId: "3344556677",
                instaPostURL: "https://instagram.com/p/musinsa888",
                likeCount: "980",
                captionSummary: "무신사 스트리트 브랜드 팝업 요약",
                caption: "신진 디자이너 브랜드들을 모아놓은 무신사 팝업스토어입니다.",
                imageURL: "img_7",
                mediaType: .image
            ),
            Popup(
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                region: "서울",
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_7",
                mediaType: .image
            )
        ]
        
    }()
}

