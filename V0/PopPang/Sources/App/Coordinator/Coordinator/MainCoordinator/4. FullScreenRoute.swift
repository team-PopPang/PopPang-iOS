//
//  FullScreenRoute.swift
//  PopPang
//
//  Created by 김동현 on 11/25/25.
//

import SwiftUI

enum FullScreenRoute: Identifiable {
    var id: String { String(describing: self) }
    case search(uuid: String)
}

extension Coordinator where F == FullScreenRoute {
    
    @ViewBuilder
    func buildView(for route: F) -> some View {
        switch route {
        case .search(let userUuid):
            SearchView(userUuid: userUuid)
                .accessibilityIdentifier("home_search")
        }
    }
}



