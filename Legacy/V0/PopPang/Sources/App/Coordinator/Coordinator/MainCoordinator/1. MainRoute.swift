//
//  MainRoute.swift
//  PopPang
//
//  Created by 김동현 on 11/25/25.
//

import SwiftUI

enum MainRoute: Hashable {
    
    // Home
    case alert(uuid: String)
    case popupDetail(String, Popup)
    case comingPopupDetail
    
    // profile
    case profileSetting
    case notification
    case service
    
    // PopupDetail
    case reviewDetail([Review])
}

extension Coordinator where T == MainRoute {
    @ViewBuilder
    func buildView(for route: T) -> some View {
        switch route {
        case .alert(let userUuid):
            AlertView(userUuid: userUuid)
        case .popupDetail(let userUuid, let popup):
            PopupDetailView(userUuid: userUuid, popup: popup)
        case .comingPopupDetail:
            ComingPopupDetailView()
            
        // profile
        case .profileSetting:
            ProfileSettingView()
            
        case .notification:
            NotificationView()
            
        case .service:
            ServiceTermsView()
            
        // PopupDetail
        case .reviewDetail(let reviewList):
            ReviewDetailView(reviewList: reviewList);
        }
    }
}
