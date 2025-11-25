//
//  OverlayRoute.swift
//  PopPang
//
//  Created by 김동현 on 11/25/25.
//

import SwiftUI

enum OverlayRoute: Identifiable {

    var id: String {
        String(describing: self)
    }
    
    case notice(title: String, content: String, isCenter: Bool = false)
    case ad(image: String)
}

extension Coordinator where O == OverlayRoute {
    @ViewBuilder
    func buildView(for overlay: O) -> some View {
        switch overlay {
        case .notice(let title, let content, let isCenter):
            CustomPopupView(title: title,
                            content: content,
                            onDismiss: self.dismissOverlay,
                            isCenter: isCenter)
            
        case .ad(let image):
            AdCustomPopupView(imageURL: image,
                              title: nil,
                              content: nil,
                              onDismiss: self.dismissOverlay,
                              onDontShowToday: self.dismissOverlay)
        }
    }
}
