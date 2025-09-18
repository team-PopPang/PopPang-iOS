//
//  RegisterCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

//enum RegisterRoute: Hashable {
//    case nickname
//    case category
//}
//
//struct RegisterContainer<Content: View>: View {
//    
//    @StateObject private var coordinator = Coordinator<RegisterRoute, SheetRoute>()
//    
//    let content: () -> Content
//    var body: some View {
//        NavigationStack(path: $coordinator.paths) {
//            content()
//                .navigationDestination(for: RegisterRoute.self) { route in
//                    switch route {
//                        case .nickname:
//                            NicknameSettingView()
//                        case .category:
//                            CategorySettingView()
//                        }
//                }
//        }
//        .environmentObject(coordinator)
//    }
//}
