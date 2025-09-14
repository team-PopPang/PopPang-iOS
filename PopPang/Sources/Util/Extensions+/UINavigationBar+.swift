//
//  UINavigationBar+.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import UIKit

extension UINavigationBar {
    static func configureAppearance() {
        // 네비게이션바 전역 객체 생성
        let defaultAppearance = UINavigationBarAppearance()
        
        // 뒤로가기 버튼 텍스트 숨기기
        let backAppearance = UIBarButtonItemAppearance()
        backAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        defaultAppearance.backButtonAppearance = backAppearance
        
        // 네비게이션바 타이틀 텍스트 스타일(폰트, 색상)
        defaultAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 26),
            .foregroundColor: UIColor.black
        ]
        
        // 뒤로가기 화살표(chevron) 아이콘 설정
        // - 크기: 20pt
        // - 두께: light
        // - 색상: mainOrange
        // - 위치: 왼쪽으로 -8 이동 (화면 가장자리에 더 가깝게)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
        let chevronImage = UIImage(systemName: "chevron.left", withConfiguration: config)?
            .withTintColor(UIColor(.mainOrange), renderingMode: .alwaysOriginal)
            .withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0))
        defaultAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        
        // 앱 전역 UINavigationBar appearance 적용
        // - standardAppearance: 기본 높이
        // - compactAppearance: landscape 등 압축 높이
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = defaultAppearance
        navigationBar.compactAppearance = defaultAppearance
    }
}
