//
//  PopupDetailViewModel.swift
//  PopPang
//
//  Created by 김동현 on 11/1/25.
//

import Foundation
import Kingfisher

struct Review: Identifiable, Hashable {
    var id = UUID()
    let nickname: String
    let info: String
    let starCount: Int
}

final class PopupDetailViewModel: ObservableObject {
    @Dependency var popupUsecase: PopupUsecaseProtocol
    @Dependency var adminUsecase: AdminUsecaseProtocol
    let userUuid: String
    @Published var popup: Popup
    @Published var relatedPopupList: [Popup] = []
    
    let mockReview: [Review] = [
        Review(nickname: "홍길동", info: "정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!", starCount: 5),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 3),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 5),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(nickname: "홍길동", info: "정말 재미있어요! 정말 재미있어요! 정말 재미있어요! 정말 재미있어요!", starCount: 3)
    ]
    
    init(userUuid: String, popup: Popup) {
        self.userUuid = userUuid
        self.popup = popup
        
        Task {
            await getPersonalRelatedPopupList(userUuid: userUuid, popupUuid: popup.popupUuid)
        }
    }
}

// MARK: - 조회수 관련
extension PopupDetailViewModel {
    
    // 조회수 증가 요청
    func increaseViewCount(popupUuid: String) async {
        do {
            try await popupUsecase.increaseViewCount(popupUuid: popupUuid)
        } catch {
            print("❌ 조회수 증가 오류: \(error)")
        }
    }
    
    // 이미지 캐싱 로직
    func prefetchImages(urls: [String]) {
        
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            ImageCache.default.retrieveImage(forKey: url.cacheKey) { result in
                switch result {
                case .success(let value):
                    if value.image == nil {
                        // 메모리/디스크에 캐시가 없을 경우 다운로드 실행
                        KingfisherManager.shared.retrieveImage(with: url) { _ in
                            // Logger.d("Preloaded \(url)")
                        }
                    } else {
                        // Logger.d("Already cached \(url)")
                    }
                case .failure:
                    // 실패한 경우도 다시 다운로드 시도
                    KingfisherManager.shared.retrieveImage(with: url) { _ in
                        // Logger.d("Preloaded \(url)")
                    }
                }
            }
        }
    }
}

// MARK: - 찜 관련
extension PopupDetailViewModel {
    /// 팝업이 찜 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        popup.isFavorited
    }
    
    /// 찜 상태 바꿔주는 함수
    func toggleLike() async {
        do {
            if popup.isFavorited {
                Logger.d("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                await MainActor.run {
                    self.popup.isFavorited = false
                    let count = popup.favoriteCount
                    self.popup.favoriteCount = max(0, count - 1)
                }
            } else {
                Logger.d("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                await MainActor.run {
                    self.popup.isFavorited = true
                    self.popup.favoriteCount = (popup.favoriteCount) + 1
                }
            }
        } catch {
            Logger.e("❌ 찜 토글 실패: \(error)")
        }
    }
}

// MARK: - 연관 팝업 추천 관련
extension PopupDetailViewModel {
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async {
        
        do {
            let popups = try await popupUsecase.getPersonalRelatedPopupList(userUuid: userUuid,
                                                                            popupUuid: popupUuid)
            
            await MainActor.run {
                self.relatedPopupList = popups
            }
            
        } catch {
            Logger.e("\(error)")
        }
    }
}

// MARK: - 관리자 관련
extension PopupDetailViewModel {
    func deactivatePopup(userUuid: String, popupUuid: String) async {
        do {
            try await adminUsecase.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid)
        } catch {
            Logger.e("❌ 관리자 팝업 비활성화 실패: \(error)")
        }
    }
}

