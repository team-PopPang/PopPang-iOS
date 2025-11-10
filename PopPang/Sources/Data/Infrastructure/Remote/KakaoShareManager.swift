////
////  KakaoShareManager.swift
////  PopPang
////
////  Created by 김동현 on 10/25/25.
////
//
//import Foundation
//import KakaoSDKCommon
//import KakaoSDKShare
//import KakaoSDKTemplate
//import SafariServices
//import UIKit
//
//final class KakaoShareManager {
//    static let shared = KakaoShareManager()
//    private init() {}
//
//    /// 웹/앱 버튼 모두 있는 기본 공유
//    func share(url: String,
//               title: String,
//               description: String,
//               imageUrl: String) {
//        guard let shareUrl = URL(string: url),
//              let imageURL = URL(string: imageUrl) else {
//            print("❌ URL 변환 실패")
//            return
//        }
//
//        let link = Link(
//            webUrl: shareUrl,
//            mobileWebUrl: shareUrl
//        )
//
//        let button1 = Button(title: "웹으로 보기", link: link)
//        let button2 = Button(
//            title: "앱으로 보기",
//            link: Link(iosExecutionParams: ["popupId": url])
//        )
//
//        let content = Content(
//            title: title,
//            imageUrl: imageURL,
//            description: description,
//            link: link
//        )
//
//        let feedTemplate = FeedTemplate(content: content, buttons: [button1, button2])
//
//        shareWithTemplate(feedTemplate)
//    }
//
//    /// “앱으로 보기”만 있는 버전
//    func shareAppOnly(
//        url: String,
//        title: String,
//        description: String,
//        imageUrl: String,
//        popupId: String         // ✅ 동일하게 popupId 추가
//    ) {
//        guard let shareUrl = URL(string: url),
//              let imageURL = URL(string: imageUrl) else {
//            print("❌ URL 변환 실패")
//            return
//        }
//
//        let button = Button(
//            title: "앱으로 보기",
//            link: Link(iosExecutionParams: ["popupId": popupId])  // ✅ popupId 전달
//        )
//
//        let content = Content(
//            title: title,
//            imageUrl: imageURL,
//            description: description,
//            link: Link(webUrl: shareUrl,                         
//                       mobileWebUrl: shareUrl,
//                       iosExecutionParams: ["popupId": popupId])
//        )
//
//        let feedTemplate = FeedTemplate(content: content, buttons: [button])
//        shareWithTemplate(feedTemplate)
//    }
//
//    /// 실제 공유 처리 로직 (중복 제거)
//    // MARK: - 카카오톡 설치여부 확인
//    private func shareWithTemplate(_ feedTemplate: FeedTemplate) {
//        // 카카오톡으로 공유 가능
//        if ShareApi.isKakaoTalkSharingAvailable() {
//            ShareApi.shared.shareDefault(templatable: feedTemplate) { (result, error) in
//                if let error = error {
//                    print("❌ 공유 실패:", error)
//                } else if let result = result {
//                    UIApplication.shared.open(result.url, options: [:], completionHandler: nil)
//                }
//            }
//        } else {
//            // 카카오 미설치로 웹 공유
//            if let url = ShareApi.shared.makeDefaultUrl(templatable: feedTemplate) {
//                let safariVC = SFSafariViewController(url: url)
//                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                   let rootVC = scene.windows.first?.rootViewController {
//                    rootVC.present(safariVC, animated: true)
//                }
//            }
//        }
//    }
//}

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
    private let appStoreURL = "https://apps.apple.com/kr/app/하루한컷-하루를-하나의-컷으로-담다/id6743386583"

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
