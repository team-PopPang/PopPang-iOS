//
//  KFImage+.swift
//  PopPang
//
//  Created by 김동현 on 1/6/26.
//

import SwiftUI
import Kingfisher

enum ImagePresent {
    case small
    case medium
    case large
    case bestPopupCell
    case comingPopupCell
    case gridPopupCell
}

extension ImagePresent {
    var size: CGSize {
        switch self {
        case .small:  return CGSize(width: 106, height: 133)
        case .medium: return CGSize(width: 106, height: 133)
        case .large:  return CGSize(width: 194, height: 271) // BestPopupCell
        case .bestPopupCell:  return CGSize(width: 194, height: 271)
        case .comingPopupCell:  return CGSize(width: 283, height: 138)
        case .gridPopupCell: return CGSize(width: (UIScreen.main.bounds.width - 15 * 3) / 2, height: 217)
        }
    }
}

extension KFImage {
    /// 다운샘플링 + 스케일 + 캐시
    /// - present: "이 이미지를 어디에 쓰는지" (썸네일/카드/상세 등) → 목표 사이즈를 결정
    /// - scale: Retina(2x/3x) 대응. 기본값은 현재 기기 스케일
    func downSampled(_ present: ImagePresent, scale: CGFloat = UIScreen.main.scale) -> some View {
        self
            // 1) DownsamplingImageProcessor
            // - 핵심: "다운로드 후 리사이즈"가 아니라 "디코딩 단계에서 목표 크기로 줄여서" 메모리에 올림
            // - 효과: 원본(큰) 이미지를 통째로 디코딩해서 메모리에 올리는 비용을 줄임
            // - 특히 List/Scroll에서 이미지가 많을 때 메모리/CPU 부담 크게 감소
            .setProcessor(DownsamplingImageProcessor(size: present.size))
        
            // 2) scaleFactor
            // - 다운샘플링할 때 픽셀 밀도(2x/3x)를 반영
            // - 예: 80pt 썸네일이라도 3x 기기면 실제로는 240px 수준의 디테일이 필요
            // - 이 값이 없으면 뿌옇게 보이거나, 불필요한 리스케일이 생길 수 있음
            // - 1pt를 몇 px로 보이게 하는지 알려주는 값
            .scaleFactor(scale)
            
            // 3) cacheOriginalImage
            // - "원본을 캐시한다" 라기보다
            // - 이 요청(=URL + Processor + 옵션들)의 결과 이미지를 캐시에 잘 보관하도록 유도하는 옵션
            // - 같은 URL을 같은 옵션으로 다시 요청하면 재처리(다운샘플/디코딩) 비용을 줄일 수 있음
            //
            // ⚠️ 네이밍이 헷갈리지만, 실무에선:
            // "재사용 성능"을 위해 자주 켜는 옵션이라고 이해하면 됨
            .cacheOriginalImage()
        
            .resizable()
    }
}
