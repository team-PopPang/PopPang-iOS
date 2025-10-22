//
//  ItemKey.swift
//  PopPang
//
//  Created by 김동현 on 10/23/25.
//

import NMapsMap


/// NSObject: NMCClusteringKey 프로토콜이 Object-C 기반이라 NSObject를 상속해야함
/// NMCClusteringKey: 네이버 지도 SDK 클러스터링에 필요한 Key 타입 프로토콜
final class ItemKey: NSObject, NMCClusteringKey {
    let identifier: Int
    let position: NMGLatLng
    let popup: Popup
    
    
    init(identifier: Int,
         position: NMGLatLng,
         popup: Popup
    ) {
        self.identifier = identifier
        self.position = position
        self.popup = popup
    }
    
    
    /// 두 ItemKey객체가 같은지 판별 메서드(Identifier기준으로 비교)
    /// - Parameter object: 비교 대상 객체
    /// - Returns: 두 객체의 identifier가 같은지 여부
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ItemKey else { return false }
        return identifier == other.identifier
    }
    
    
    /// 딕셔너리처럼 클러스터링 키의 빠른 비교를 위한 해시값
    override var hash: Int {
        return self.identifier
    }
    
    
    /// 클러스터는 내부족으로 key 객체를 복제해서 관리할 수 있으므로
    /// 프로토콜에 따라 copy 메서드를 구현해야 함
    /// ItemKey의 동일한 값을 가진 새로운 신스턴스를 반환
    /// - Parameter zone: 메모리 영역(nil)
    /// - Returns: 동일한 값을 가진 새로운 ItemKey 인스턴스
    func copy(with zone: NSZone? = nil) -> Any {
        return ItemKey(identifier: self.identifier, position: self.position, popup: self.popup)
    }
}

import Kingfisher

/*
// 모여있는 클러스터 마커 스타일
final class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo,
                                      _ marker: NMFMarker
    ) {
        super.updateClusterMarker(info, marker)
        marker.iconImage = info.size < 5
        ? NMF_MARKER_IMAGE_CLUSTER_LOW_DENSITY
        : NMF_MARKER_IMAGE_CLUSTER_MEDIUM_DENSITY
    }
}

// 단일 마컷 스타일
final class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var onTap: ((Popup) -> Void)?
    
    override func updateLeafMarker(_ info: NMCLeafMarkerInfo,
                                   _ marker: NMFMarker
    ) {
        super.updateLeafMarker(info, marker)
        guard let key = info.key as? ItemKey else { return }
        
        // 기본 마커 스타일 변경
        marker.width = 50
        marker.height = 50
        marker.captionText = ""
        
        // ✅ 테스트용: 일단 기본 파란 마커로만 표시
        marker.iconImage = NMF_MARKER_IMAGE_BLUE
        
        // 마커 클릭 시 팝업 디테일 이동
        marker.touchHandler = { [weak self] _ in
            self?.onTap?(key.popup)
            return true
        }
        

        
        /*
        // 마커 이미지 로드
        if let imageURL = URL(string: key.popup.imageUrlList.first ?? "") {
            Task {
                if let roundedImage = await Self.makeRoundedMarkerImage(from: imageURL) {
                    marker.iconImage = NMFOverlayImage(image: roundedImage)
                } else {
                    marker.iconImage = NMF_MARKER_IMAGE_BLUE
                }
            }
        } else {
            marker.iconImage = NMF_MARKER_IMAGE_BLUE
        }
         */
    }
    
    /// URL로부터 이미지를 불러와 둥근 사각형 UIImage로 변환
    static func makeRoundedMarkerImage(from url: URL, size: CGSize = CGSize(width: 50, height: 50)) async -> UIImage? {
        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                result.image.draw(in: rect)
            }
        } catch {
            return nil
        }
    }
}

*/

class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        if info.size < 3 {
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_LOW_DENSITY
        } else {
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_MEDIUM_DENSITY
        }
    }
}

final class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var onTap: ((Popup) -> Void)?
    
    override func updateLeafMarker(_ info: NMCLeafMarkerInfo,
                                   _ marker: NMFMarker
    ) {
        super.updateLeafMarker(info, marker)
        guard let key = info.key as? ItemKey else { return }
        
        // 기본 마커 스타일 변경
        marker.width = 50
        marker.height = 50
        marker.captionText = ""
        
        // ✅ 테스트용: 일단 기본 파란 마커로만 표시
        marker.iconImage = NMF_MARKER_IMAGE_BLUE
        
        // 마커 클릭 시 팝업 디테일 이동
        marker.touchHandler = { [weak self] _ in
            self?.onTap?(key.popup)
            return true
        }
    }
    
    /// URL로부터 이미지를 불러와 둥근 사각형 UIImage로 변환
    static func makeRoundedMarkerImage(from url: URL, size: CGSize = CGSize(width: 50, height: 50)) async -> UIImage? {
        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                result.image.draw(in: rect)
            }
        } catch {
            return nil
        }
    }
}
