//
//  MainCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

//import SwiftUI
//
//enum MainRoute: Hashable {
//    case home
//    case calendar
//    case map
//    case bookmark
//    case profile
//}
//
//enum SheetRoute: Identifiable {
//    var id: String {
//        String(describing: self)
//    }
//}
//
//extension Coordinator where T == MainRoute {
//    @ViewBuilder
//    func buildView(for route: T) -> some View {
//        // let factory = ViewModelFactory.shared
//        
//        switch route {
//        case .home:
//            HomeView()
//            // HomeView(viewModel: factory.makeHomeViewModel())
//        case .calendar:
//            CalendarView()
//        case .map:
//            MapView()
//        case .bookmark:
//            BookmarkView()
//        case .profile:
//            ProfileView()
//        }
//    }
//}


import SwiftUI

enum MainRoute: Hashable {
    
    // Home
    case search
    case alert
}

enum SheetRoute: Identifiable {
    var id: String {
        String(describing: self)
    }
}

enum OverlayRoute: Identifiable {
    case notice(title: String, content: String)
    
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
        }
    }
}
