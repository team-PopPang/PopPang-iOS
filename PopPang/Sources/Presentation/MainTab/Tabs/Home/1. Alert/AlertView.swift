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
            
            // 우측 삭제 버튼
            ToolbarItem(placement: .topBarTrailing) {
                
                TrashButton(isEditing: activityViewModel.isEditing) {
                    if activityViewModel.isEditing {
                        // 삭제 확인 알림 보내기
                        activityViewModel.showDeleteAlert = true
                        
                    } else {
                        // 편집 모드 실행
                        activityViewModel.isEditing = true
                    }
                }
                .alert("정말로 삭제하시겠습니까?",
                       isPresented: $activityViewModel.showDeleteAlert) {
                    Button("삭제", role: .destructive) {
                        activityViewModel.deleteSelectedPopups()
                        activityViewModel.isEditing = false
                    }
                    Button("취소", role: .cancel) { }
                } message: {
                    Text("선택한 팝업이 삭제됩니다.")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertView(userUuid: "1234")
            .environmentObject(HomeViewModel(userUuid: "1234"))
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

struct TrashButton: View {
    var isEditing: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            if isEditing {
                Text("완료")
                    .ppStyleFont(.scdream(.medium, size: 15))
            } else {
                Image(systemName: "trash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .padding(10)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
