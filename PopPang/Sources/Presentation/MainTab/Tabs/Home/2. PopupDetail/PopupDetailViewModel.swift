//
//  PopupDetailViewModel.swift
//  PopPang
//
//  Created by 김동현 on 11/1/25.
//

import Foundation
import Kingfisher

final class PopupDetailViewModel: ObservableObject {
    @Dependency var popupUsecase: PopupUsecaseProtocol
}

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
