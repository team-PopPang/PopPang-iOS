//
//  MainCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

typealias MainCoordinator = Coordinator<MainRoute, SheetRoute, OverlayRoute>

enum MainRoute: Hashable {
    
    // Home
    case alert(uuid: String)
    case popupDetail(Popup)
    
    // profile
    case profileSetting
    case notification
    
    // case notice
    // case contectUs      // 문의하기
    // case termsOfService // 이용약관
}

enum SheetRoute: Identifiable {
    var id: String {
        String(describing: self)
    }
    
    case search(uuid: String)
}

enum OverlayRoute: Identifiable {
    case notice(title: String, content: String, isCenter: Bool = false)
    case ad(image: String)
    
    var id: String {
        String(describing: self)
    }
}

extension Coordinator where T == MainRoute {
    @ViewBuilder
    func buildView(for route: T) -> some View {
        switch route {
        case .alert(let userUuid):
            AlertView(userUuid: userUuid)
        case .popupDetail(let popup):
            PopupDetailView(popup: popup)
            
        // profile
        case .profileSetting:
            ProfileSettingView()
            
        case .notification:
            NotificationView()
        }
    }
}

extension Coordinator where O == OverlayRoute {
    @ViewBuilder
    func buildView(for overlay: O) -> some View {
        switch overlay {
        case .notice(let title, let content, let isCenter):
            CustomPopupView(title: title,
                            content: content,
                            onDismiss: self.dismissOverlay,
                            isCenter: isCenter
            )
        case .ad(let image):
            AdCustomPopupView(imageURL: image,
                              title: nil,
                              content: nil,
                              onDismiss: self.dismissOverlay,
                              onDontShowToday: self.dismissOverlay)
        }
    }
}

extension Coordinator where R == SheetRoute {
    @ViewBuilder
    func buildView(for route: R) -> some View {
        switch route {
        case .search(let userUuid):
            SearchView(userUuid: userUuid)
        }
    }
}
