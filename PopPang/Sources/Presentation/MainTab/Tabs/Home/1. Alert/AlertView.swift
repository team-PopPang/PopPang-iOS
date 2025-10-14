//
//  AlertView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @StateObject private var activityViewModel: ActivityViewModel
    @StateObject private var keywordViewModel: KeywordViewModel
    let uuid: String
    private let segments = ["활동", "키워드 설정"]
    
    init(uuid: String) {
        self.uuid = uuid
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(uuid: uuid))
        _keywordViewModel = StateObject(wrappedValue: KeywordViewModel(uuid: uuid))
    }
    
    var body: some View {
        VStack(spacing: 0) {

            // ✅ 세그먼트 헤더
            SegmentedControlView(segments: segments,
                                 views: [ActivityView(activityViewModel: activityViewModel),
                                         KeywordView(keywordViewModel: keywordViewModel)],
                                 background: .mainGray3,
                                 foreground: .mainOrange,
                                 font: .scdream(.medium, size: 12))
        }
        // toolbar
        .toolbar {
            // 커스텀 타이틀
            ToolbarItem(placement: .principal) {
                Text("알림")
                    .ppStyleFont(.scdream(.medium, size: 20))
                    .padding(.top, 10)
            }
            
            // 커스텀 우측
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image("gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertView(uuid: "1234")
            .environmentObject(HomeViewModel())
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

//final class AlertViewModel: ObservableObject {
//    let uuid: String
//    
//    init(uuid: String) {
//        self.uuid = uuid
//        print("uuid출력: \(uuid)")
//    }
//}
