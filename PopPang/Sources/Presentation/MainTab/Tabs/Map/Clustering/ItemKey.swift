//
//  ItemKey.swift
//  PopPang
//
//  Created by 김동현 on 10/24/25.
//

import NMapsMap

class ItemKey: NSObject, NMCClusteringKey {
    let identifier: Int
    let position: NMGLatLng
    let imageURL: String

    init(identifier: Int, position: NMGLatLng, imageURL: String) {
        self.identifier = identifier
        self.position = position
        self.imageURL = imageURL
    }

    static func markerKey(withIdentifier identifier: Int, position: NMGLatLng, imageURL: String) -> ItemKey {
        return ItemKey(identifier: identifier, position: position, imageURL: imageURL)
    }

    override func isEqual(_ o: Any?) -> Bool {
        guard let o = o as? ItemKey else {
            return false
        }
        if self === o {
            return true
        }

        return o.identifier == self.identifier
    }

    override var hash: Int {
        return self.identifier
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return ItemKey(identifier: self.identifier, position: self.position, imageURL: self.imageURL)
    }
}

/// 클러스터 마커 디자인을 커스터마이징하기 위한 클래스
/// - NMCDefaultClusterMarkerUpdater 를 상속받아 오버라이드 함
/// - 클러스터에 포함된 마커 개수(info.size)에 따라 다른 아이콘 이미지를 적용
class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    
    /// 클러스터 마커를 업데이트할 때 호출되는 메서드
    /// - Parameters:
    ///   - info: 클러스터 마커에 대한 정보 (몇 개의 마커가 묶였는지 등)
    ///   - marker: 실제 지도에 표시될 클러스터 마커 객체
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        
        let count = info.size
    
        if count < 3 {
            // 마커가 2개 이하일 경우 — 저밀도 아이콘 사용
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_LOW_DENSITY
        } else {
            // 마커가 3개 이상일 경우 — 중간 밀도 아이콘 사용
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_MEDIUM_DENSITY
        }

        /*
        // 커스텀 사용시
        if count < 3 {
            marker.iconImage = NMFOverlayImage(name: "circle_fill")
        } else if count < 10 {
            marker.iconImage = NMFOverlayImage(name: "cluster_medium")
        } else {
            marker.iconImage = NMFOverlayImage(name: "cluster_large")
        }
         */
    }
}





import NMapsMap
import Kingfisher
import UIKit

class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var clusterer: NMCClusterer<ItemKey>?
    var onMarkerSelected: ((ItemKey) -> Void)?
    var onMarkerCreated: ((NMFMarker, ItemKey) -> Void)?

    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)

        guard let key = info.key as? ItemKey,
              let imageURL = URL(string: key.imageURL) else { return }
        
        // 마커 생성 직후 callback → MapCoordinator에서 저장하게 함
        onMarkerCreated?(marker, key)

        Task {
            if let roundedImage = await makeRoundedMarkerImage(from: imageURL, size: CGSize(width: 60, height: 60)) {
                await MainActor.run {
                    marker.iconImage = NMFOverlayImage(image: roundedImage)
                    marker.width = 60
                    marker.height = 60
                }
            }
        }

        marker.touchHandler = { [weak self] _ in
            self?.onMarkerSelected?(key) // 외부로 콜백 전달
            // print("📍 리프 마커 클릭됨")
            return true
        }
    }

    /// 📌 네트워크 이미지를 불러와 네모 박스로 변환하는 함수
    func makeRoundedMarkerImage(from url: URL, size: CGSize = CGSize(width: 40, height: 40)) async -> UIImage? {
        do {
            // Kingfisher로 이미지 비동기 로드
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let originalImage = result.image

            // 렌더러로 모서리 둥근 사각형 만들기
            let renderer = UIGraphicsImageRenderer(size: size)
            let roundedImage = renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                originalImage.draw(in: rect)
            }
            return roundedImage
        } catch {
            print("❌ 이미지 로드 실패: \(error)")
            return nil
        }
    }
}

