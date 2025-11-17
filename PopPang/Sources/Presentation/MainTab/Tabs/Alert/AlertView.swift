//
//  AlertView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @StateObject private var activityViewModel: ActivityViewModel
    @StateObject private var keywordViewModel: KeywordViewModel
    let userUuid: String
    private let segments = ["활동", "키워드 설정"]
    
    init(userUuid: String) {
        self.userUuid = userUuid
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(userUuid: userUuid))
        _keywordViewModel = StateObject(wrappedValue: KeywordViewModel(userUuid: userUuid))
    }
    
    var body: some View {
        VStack(spacing: 0) {

            // 세그먼트 헤더
            SegmentedControlView(segments: segments,
                                 views: [ActivityView(activityViewModel: activityViewModel),
                                         KeywordView(keywordViewModel: keywordViewModel, activityViewModel: activityViewModel)],
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
            
            // 우측 삭제 버튼
            ToolbarItem(placement: .topBarTrailing) {
                
                TrashButton(isEditing: activityViewModel.isEditing) {
                    
                    if activityViewModel.isEditing {
                        activityViewModel.isEditing = false
                    } else {
                        // 편집 모드 실행
                        activityViewModel.isEditing = true
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertView(userUuid: "1234")
            .environmentObject(RootViewModel())
            .environmentObject(HomeViewModel(userUuid: "1234"))
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

struct TrashButton: View {
    var isEditing: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 완료 텍스트
                Text("완료")
                    .ppStyleFont(.scdream(.medium, size: 15))
                    .opacity(isEditing ? 1 : 0)
                
                // 편집 텍스트
                Text("편집")
                    .ppStyleFont(.scdream(.medium, size: 15))
                    .opacity(isEditing ? 0 : 1)

                // 휴지통 아이콘
                /*
                Image(systemName: "trash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(10)
                    .opacity(isEditing ? 0 : 1)
                 */
            }
        }
        .buttonStyle(PressableButtonStyle())
        .animation(nil, value: isEditing) // 안전하게 무효화
    }
}


//struct TrashButton: View {
//    var isEditing: Bool
//    var action: () -> Void
//    
//    var body: some View {
//        Button {
//            action()
//        } label: {
//            
//            if isEditing {
//                Text("완료")
//                    .ppStyleFont(.scdream(.medium, size: 15))
//            } else {
//                Image(systemName: "trash")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 20, height: 20)
//                    .padding(10)
//                    .clipShape(RoundedRectangle(cornerRadius: 6))
//                    .contentShape(RoundedRectangle(cornerRadius: 6))
//            }
//        }
//        .buttonStyle(PressableButtonStyle())
//    }
//}
