//
//  MapSheetView.swift
//  PopPang
//
//  Created by 김동현 on 10/19/25.
//

import SwiftUI

extension View {
    /**
     시트(sheet) 또는 기타 하단 뷰가 **탭바(Tab Bar)** 영역과 **Safe Area(bottom)** 를 침범하지 않도록
     하단 높이를 잘라내는 Modifier입니다.
     
     iPhone X 이후 기종(홈 인디케이터가 있는 기기)은
     - 탭바 높이(49pt)
     - Safe Area bottom(34pt)
     를 합쳐 **총 83pt**의 여백이 필요합니다.
     
     이를 수동으로 계산하지 않고, `.mapSheet()` Modifier를 적용하면
     기기 환경에 맞춰 자동으로 여백을 잘라내 시트가 깔끔하게 정렬됩니다.
     
     예시:
     ```swift
      .sheet(isPresented: $showSheet) {
          VStack {
              Text("지도 시트")
          }
          .presentationDetents([.medium, .large])
          .mapSheet(49) // ✅ 탭바 + SafeArea 고려해서 자동 보정
      }
     ```
     */
    /// 탭바 높이 + safeArea bottom 고려해
    /// 시트나 다른 뷰가 하단을 침범하지 않도록 잘라내는 Modifier
    /// - Parameter bottomPadding: (시트가 바닥에서 알마나 패딩을 줄지 = 탭바 높이)
    /// - Returns: 시트
    @ViewBuilder
    func mapSheet(_ bottomPadding: CGFloat = 49) -> some View {
        self.background(
            MapSheetView(bottomPadding: bottomPadding)
        )
    }
}

fileprivate extension UIView {
    
    /// 현재 UIView에서 UIWindow까지 거슬러 올라가 **루트 뷰 직전의 UIView**를 반환합니다.
    /// → 시트가 실제로 위치하는 상위 뷰(Frame 조정을 위해 필요).
    var viewBeforeWindow: UIView? {
        if let superview, superview is UIWindow {
            return self
        }
        return superview?.viewBeforeWindow
    }
    
    /// 현재 UIView의 **모든 하위 서브뷰**를 재귀적으로 펼쳐 반환합니다.
    /// → shadow나 cornerRadius를 제거할 때 필요한 대상 탐색용.
    var allSubView: [UIView] {
        return subviews.flatMap { [$0] + $0.subviews }
    }
}

/**
 SwiftUI에서는 시트의 하단 여백을 직접 제어하기 어렵기 때문에,
 `UIViewRepresentable`을 통해 UIKit 뷰를 백그라운드에 심어
 시트의 **루트 UIView frame을 조정하는 역할**을 합니다.

 - 탭바 높이 + SafeArea bottom 값을 합산해서 시트 높이에서 감산
 - 시트 하단이 탭바를 덮지 않게 조정
 - 그림자 및 둥근 모서리 효과 제거로 깔끔한 UI 연출
 */
private struct MapSheetView: UIViewRepresentable {
    
    /// 시트에서 잘라낼 하단 높이(기본 49pt)
    var bottomPadding: CGFloat
    
    func makeCoordinator() -> _Coordinator {
        _Coordinator()
    }
    
    /// SwiftUI에 삽입될 UIView를 생성합니다.
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    /// SwiftUI 뷰 업데이트 시 호출되며,
    /// 루트 뷰의 frame을 조정하고, 그림자/모서리 스타일을 제거합니다.
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard !context.coordinator.isMasked,
                  let rootView = uiView.viewBeforeWindow else { return }
            
            let safeArea = rootView.safeAreaInsets
            rootView.frame = .init(
                origin: .zero,
                size: .init(
                    width: rootView.frame.width,
                    height: rootView.frame.height - (bottomPadding + safeArea.bottom)
                )
            )
            
            rootView.clipsToBounds = true
            
            // 그림자 제거 및 cornerRadius 초기화
            for view in rootView.subviews {
                view.layer.shadowColor = UIColor.clear.cgColor
                if view.layer.animationKeys() != nil {
                    if let cornerRadiusView = view.allSubView.first(where: {
                        $0.layer.animationKeys()?.contains("cornerRadius") ?? false}) {
                        cornerRadiusView.layer.maskedCorners = []
                    }
                }
            }
            
            // 한 번만 적용되도록 상태 저장
            context.coordinator.isMasked = true
        }
    }
    
    /// Coordinator는 같은 시트에서 여러 번 update되는 경우 중복 적용을 방지합니다.
    final class _Coordinator: NSObject {
       // Status
       var isMasked: Bool = false
   }
}
