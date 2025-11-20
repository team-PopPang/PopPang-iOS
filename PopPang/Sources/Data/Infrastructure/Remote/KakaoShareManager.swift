//
//  KakaoShareManager.swift
//  PopPang
//
//  Created by 김동현 on 10/25/25.
//

import Foundation
import KakaoSDKCommon
import KakaoSDKShare
import KakaoSDKTemplate
import SafariServices
import UIKit

final class KakaoShareManager {
    static let shared = KakaoShareManager()
    private init() {}

    private let baseUniversalLink = "https://poppang.co.kr/popup/"
    private let appStoreURL = "https://apps.apple.com/kr/app/팝팡/id6753014613"

    /// ✅ 유니버설 링크 + App Store fallback
    func shareAppOnly(
        title: String,
        description: String,
        imageUrl: String,
        popupId: String
    ) {
        guard let imageURL = URL(string: imageUrl) else { return }

        let universalLink = "\(baseUniversalLink)\(popupId)"

        // ✅ Kakao SDK는 iosExecutionParams를 기반으로 앱 실행 판단
        let link = Link(
            webUrl: URL(string: appStoreURL),      // 앱 미설치 시 → 앱스토어
            mobileWebUrl: URL(string: appStoreURL),
            iosExecutionParams: ["popupId": popupId] // 앱 설치 시 → 이 값으로 앱 열림
        )

        let button = Button(title: "앱으로 보기", link: link)

        let content = Content(
            title: title,
            imageUrl: imageURL,
            description: description,
            link: Link(
                webUrl: URL(string: universalLink),
                mobileWebUrl: URL(string: universalLink),
                iosExecutionParams: ["popupId": popupId]
            )
        )

        let feedTemplate = FeedTemplate(content: content, buttons: [button])
        shareWithTemplate(feedTemplate)
    }

    private func shareWithTemplate(_ feedTemplate: FeedTemplate) {
        if ShareApi.isKakaoTalkSharingAvailable() {
            ShareApi.shared.shareDefault(templatable: feedTemplate) { result, error in
                if let error = error {
                    print("❌ 공유 실패:", error)
                } else if let result = result {
                    UIApplication.shared.open(result.url, options: [:])
                }
            }
        } else {
            if let url = ShareApi.shared.makeDefaultUrl(templatable: feedTemplate) {
                let safariVC = SFSafariViewController(url: url)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = scene.windows.first?.rootViewController {
                    rootVC.present(safariVC, animated: true)
                }
            }
        }
    }
}
