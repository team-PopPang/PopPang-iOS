//
//  BottomSheetRoute.swift
//  PopPang
//
//  Created by 김동현 on 11/26/25.
//

import SwiftUI
import BottomSheet

enum BottomSheetRoute {
    var id: String { String(describing: self) }
    case popupDetailSheet
    
    var position: BottomSheetPosition {
        switch self {
        case .popupDetailSheet: return .relative(0.5)
        }
    }
    
    var switchables: [BottomSheetPosition] {
        switch self {
        case .popupDetailSheet: return [.absolute(0),  .relative(0.5)]
        // case .popupDetailSheet: return [.absolute(0), .relative(0.25), .relative(0.5), .relative(0.9), .absolute(UIScreen.main.bounds.height)]
        }
    }
}

extension Coordinator {
    @ViewBuilder
    func buildView(for route: BottomSheetRoute) -> some View {
        switch route {
        case .popupDetailSheet:
            PopupDetailSheet()
                .environmentObject(self)
        }
    }
}

struct PopupDetailSheet: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    var body: some View {
        Text("PopupDetailSheet")
        
        Button {
             coordinator.presentBottomSheet(.popupDetailSheet)
//            coordinator.dismissBottomSheet()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                    coordinator.presentBottomSheet(.popupDetailSheet)
//                }
        } label: {
            Text("시트 또열기")
        }
    }
}
