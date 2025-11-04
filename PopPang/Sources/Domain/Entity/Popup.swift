//
//  Popup.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import Foundation

struct Popup: Hashable, Identifiable, Encodable {
    // SwiftUI용 Identifiable Id
    var id: String { popupUuid }
    let popupUuid: String
    let name: String
    let startDate: Date
    let endDate: Date
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
    let mediaType: MediaType
    let favoriteCount: Int?
    let viewCount: Int?
    
    enum MediaType: String, Codable {
        case image = "IMAGE"
        case video = "VIDEO"
        case carousel = "CAROUSEL_ALBUM"
    }
}


extension Popup {
    
    static let popupMock: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return Popup(
            popupUuid: "1234",
            name: "2025 짱구 부산 팝업스토어",
            startDate: formatter.date(from: "2025-10-13 11:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-15 20:00") ?? Date(),
            openTime: "",
            closeTime: "",
            address: "테스트 주소",
            roadAddress: "부산 해운대구 우동 123-4",
            region: "부산",
            latitude: 1,
            longitude: 2,
            instaPostId: "5566778899",
            instaPostUrl: "https://instagram.com/p/shinchan2025",
            captionSummary: """
            짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는 
            2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
            만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는 
            체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지 
            다양한 상품이 판매됩니다.\n
            특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
            웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
            """,

            imageUrlList: ["https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
                           "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_2.jpg"],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0
        )
    }()
    
    static let popupMock2: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return Popup(
            popupUuid: "12345",
            name: "2025 짱구 부산 팝업스토어",
            startDate: formatter.date(from: "2025-10-13 11:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-15 20:00") ?? Date(),
            openTime: "",
            closeTime: "",
            address: "테스트 주소",
            roadAddress: "부산 해운대구 우동 123-4",
            region: "부산",
            latitude: 1,
            longitude: 2,
            instaPostId: "5566778899",
            instaPostUrl: "https://instagram.com/p/shinchan2025",
            captionSummary: """
            짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는 
            2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
            만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는 
            체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지 
            다양한 상품이 판매됩니다.\n
            특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
            웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
            """,

            imageUrlList: ["img_8"],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0
        )
    }()
    
    static let popupMock3: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return Popup(
            popupUuid: "12345",
            name: "2025 짱구 부산 팝업스토어",
            startDate: formatter.date(from: "2025-10-13 11:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-15 20:00") ?? Date(),
            openTime: "",
            closeTime: "",
            address: "테스트 주소",
            roadAddress: "부산 해운대구 우동 123-4",
            region: "부산",
            latitude: 1,
            longitude: 2,
            instaPostId: "5566778899",
            instaPostUrl: "https://instagram.com/p/shinchan2025",
            captionSummary: """
            짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는 
            2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
            만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는 
            체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지 
            다양한 상품이 판매됩니다.\n
            특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
            웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
            """,

            imageUrlList: ["img_8"],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0
        )
    }()

 


    /*
    static let popupMocks: [Popup] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return [
            Popup(
                popupUuid: "1234",
                name: "카카오팝업스토어",
                startDate: formatter.date(from: "2025-09-27 10:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-05 22:00") ?? Date(),
                openTime: formatter.date(from: "2025-09-27 10:00") ?? Date(),
                closeTime: formatter.date(from: "2025-09-27 22:00") ?? Date(),
                address: "서울 강남구 테헤란로 123",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "1234567890",
                instaPostURL: "https://instagram.com/p/abc123",
                // likeCount: "1200",
                captionSummary: "여기는 새로운 굿즈를 선보이는 카카오팝업스토어입니다.",
                caption: "인스타 게시글 원문",
                imageURL: "img_0",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "스타벅스 한정 팝업",
                startDate: formatter.date(from: "2025-10-01 09:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-10 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-01 09:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-01 20:00") ?? Date(),
                address: "서울 마포구 합정동 456",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "0987654321",
                instaPostURL: "https://instagram.com/p/xyz789",
                // likeCount: "845",
                captionSummary: "스타벅스 신메뉴 팝업 요약",
                caption: "따뜻한 가을 한정 음료를 즐길 수 있는 스타벅스 팝업스토어입니다.",
                imageURL: "img_1",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "나이키 한정판 팝업",
                startDate: formatter.date(from: "2025-10-05 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-12 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-05 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-05 21:00") ?? Date(),
                address: "서울 송파구 올림픽로 300",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "2468135790",
                instaPostURL: "https://instagram.com/p/nike123",
                // likeCount: "1560",
                captionSummary: "나이키 한정판 신발 팝업 요약",
                caption: "한정판 스니커즈를 직접 체험할 수 있는 나이키 팝업스토어입니다.",
                imageURL: "img_2",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "레고 체험 팝업",
                startDate: formatter.date(from: "2025-09-29 10:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-15 19:00") ?? Date(),
                openTime: formatter.date(from: "2025-09-29 10:00") ?? Date(),
                closeTime: formatter.date(from: "2025-09-29 19:00") ?? Date(),
                address: "서울 용산구 이태원로 99",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "1122334455",
                instaPostURL: "https://instagram.com/p/lego456",
                // likeCount: "430",
                captionSummary: "아이와 함께 즐기는 레고 체험 팝업 요약",
                caption: "가족 단위 방문객을 위한 다양한 레고 체험 프로그램이 준비된 팝업스토어입니다.",
                imageURL: "img_3",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "올리브영 9월 팝업스토어 총정리",
                startDate: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-20 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-03 21:00") ?? Date(),
                address: "서울 마포구",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "3344556677",
                instaPostURL: "https://instagram.com/p/musinsa888",
                // likeCount: "980",
                captionSummary: "무신사 스트리트 브랜드 팝업 요약",
                caption: "신진 디자이너 브랜드들을 모아놓은 무신사 팝업스토어입니다.",
                imageURL: "img_7",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "무신사 스트리트 팝업",
                startDate: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-20 21:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-03 12:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-03 21:00") ?? Date(),
                address: "서울 성동구 성수동 88",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "3344556677",
                instaPostURL: "https://instagram.com/p/musinsa888",
                // likeCount: "980",
                captionSummary: "무신사 스트리트 브랜드 팝업 요약",
                caption: "신진 디자이너 브랜드들을 모아놓은 무신사 팝업스토어입니다.",
                imageURL: "img_7",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "2025 짱구 부산 팝업스토어",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "부산 해운대구 우동 123-4",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "부산",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/shinchan2025",
                // likeCount: "2100",
                captionSummary: """
                짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는 
                2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
                만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는 
                체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지 
                다양한 상품이 판매됩니다.\n
                특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
                웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
                """,

                caption: """
                2025 짱구 부산 팝업스토어는 단순히 굿즈를 구매하는 공간이 아니라, 팬들이 짱구의 세계 속으로 직접 들어갈 수 있도록 기획된 특별 전시입니다. 
                입구에 들어서는 순간 애니메이션 속 짱구의 집 거실과 유치원 교실이 실제 크기로 구현되어 있어, 어린 시절 TV로 보던 장면을 직접 눈앞에서 경험할 수 있습니다. 
                포토존은 단순한 배경이 아니라 AR 연출과 음향 효과가 더해져, 마치 짱구와 함께 대화하거나 흰둥이와 산책하는 듯한 몰입감을 제공합니다.  

                부산 한정으로만 판매되는 굿즈는 이번 팝업스토어의 하이라이트입니다. 짱구와 친구들이 바닷가에서 노는 장면을 담은 에코백, 텀블러, 아크릴 키링, 
                한정판 피규어, 그리고 짱구의 유행어를 새긴 티셔츠와 모자까지 다채롭게 준비되어 있으며, 현장에서만 구매 가능한 럭키박스 이벤트도 진행됩니다. 
                특히 팬들이 가장 기대하는 것은 ‘짱구 도시락 체험존’으로, 실제 애니메이션 속 짱구 도시락을 테마로 한 간단한 푸드 메뉴가 제공되어 보는 재미와 먹는 재미를 동시에 느낄 수 있습니다.  

                또한 아이들을 위한 ‘짱구 그림 교실’, 어른들을 위한 ‘추억의 짱구 영상 상영관’이 운영되어 세대 구분 없이 모두가 즐길 수 있습니다. 
                행사 마지막 주말에는 짱구 인형 탈 캐릭터와 함께하는 라이브 퍼포먼스도 예정되어 있어, 팬들에게는 평생 잊지 못할 추억이 될 것입니다.  

                이번 2025 짱구 부산 팝업스토어는 단순한 이벤트가 아니라, ‘짱구’라는 캐릭터가 가진 웃음과 유쾌함, 그리고 따뜻한 감성을 부산이라는 도시의 매력과 결합시킨 문화 축제입니다. 
                팬심으로 가득한 사람들뿐만 아니라 가족 단위 방문객, 어린 시절 향수를 찾는 어른들까지 모두가 만족할 수 있는 경험이 될 것입니다. 
                티켓은 한정 수량으로, 사전 예약과 현장 구매 모두 조기 매진이 예상되니 방문을 계획하고 있다면 서두르는 것이 좋습니다.
                """,
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            ),
            Popup(
                popupUuid: "1234",
                name: "라인프렌즈 팝업",
                startDate: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                endDate: formatter.date(from: "2025-10-25 20:00") ?? Date(),
                openTime: formatter.date(from: "2025-10-07 11:00") ?? Date(),
                closeTime: formatter.date(from: "2025-10-07 20:00") ?? Date(),
                address: "서울 중구 명동길 45",
                roadAddress: "부산 해운대구 우동 123-4",
                region: "서울",
                latitude: 1,
                longitude: 2,
                instaPostId: "5566778899",
                instaPostURL: "https://instagram.com/p/linefriends777",
                // likeCount: "2100",
                captionSummary: "라인프렌즈 인기 캐릭터 팝업 요약",
                caption: "브라운과 코니 등 인기 캐릭터 굿즈를 만나볼 수 있는 라인프렌즈 팝업스토어입니다.",
                imageURL: "img_8",
                mediaType: .image,
                errorCode: "200"
            )
        ]
        
    }()
     */
}

