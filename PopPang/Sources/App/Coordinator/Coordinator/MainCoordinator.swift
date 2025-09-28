//
//  MainCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

enum MainRoute: Hashable {
    
    // Home
    case search
    case alert
    case popupDetail(Popup)
}

enum SheetRoute: Identifiable {
    var id: String {
        String(describing: self)
    }
}

enum OverlayRoute: Identifiable {
    case notice(title: String, content: String)
    case ad(image: String)
    
    var id: String {
        String(describing: self)
    }
}

extension Coordinator where T == MainRoute {
    @ViewBuilder
    func buildView(for route: T) -> some View {
        switch route {
        case .search:
            SearchView()
        case .alert:
            AlertView()
        case .popupDetail(let popup):
            PopupDetailView(popup: popup)
        }
    }
}

extension Coordinator where O == OverlayRoute {
    @ViewBuilder
    func buildView(for overlay: O) -> some View {
        switch overlay {
        case .notice(let title, let content):
            CustomPopupView(title: title,
                            content: content,
                            onDismiss: self.dismissOverlay)
        case .ad(let image):
            AdCustomPopupView(imageURL: image,
                              title: nil,
                              content: nil,
                              onDismiss: self.dismissOverlay,
                              onDontShowToday: self.dismissOverlay)
        }
    }
}
