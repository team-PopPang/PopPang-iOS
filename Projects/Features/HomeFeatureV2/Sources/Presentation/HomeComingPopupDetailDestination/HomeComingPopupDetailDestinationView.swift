//
//  HomeComingPopupDetailDestinationView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 7/14/26.
//

import SwiftUI
import ComposableArchitecture

public struct HomeComingPopupDetailDestinationView: View {
    let store: StoreOf<HomeComingPopupDetailDestinationFeature>

    public init(store: StoreOf<HomeComingPopupDetailDestinationFeature>) {
        self.store = store
    }

    public var body: some View {
//        ComingPopupDetailFeatureView(
//            store: store.scope(state: \.content, action: \.content),
//            onSelectPopup: { _, popup in
//                store.send(.popupSelected(popup))
//            }
//        )
        EmptyView()
    }
}

