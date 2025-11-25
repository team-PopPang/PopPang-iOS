//
//  ActivityView.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import SwiftUI
import Kingfisher

struct ActivityView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @ObservedObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack {
                    if activityViewModel.isEditing {
                        Spacer()
                        Button {
                            activityViewModel.deleteAllSelectedPopups()
                        } label: {
                            Text("전체 삭제")
                                .ppStyleFont(.scdream(.regular, size: 12))
                                .foregroundStyle(Color.mainBlack)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, .contentPadding)
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                ForEach(Array(activityViewModel.alertPopupList.enumerated()), id: \.element) { index, popup in
                    AlertPopupCell(activityViewModel: activityViewModel,
                                   popup: popup)
                        .contentShape(Rectangle()) // 터치 영역을 셀 전체로 확장
                        .onTapGesture {
                            coordinator.push(.popupDetail(homeViewModel.userUuid, popup))
                        }
                        .overlay(alignment: .topTrailing) {
                            if activityViewModel.isEditing {
                                Button {
                                    activityViewModel.deleteSelectedPopups(popupUuid: popup.popupUuid)
                                } label: {
                                    Image("removeBtn")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                    

                    
                    // 마지막 셀 아래에는 Divider 넣지 않겠다
                    if index != activityViewModel.alertPopupList.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .background(Color.subWhite)
                    }
                }
            }
        }
        .padding(.horizontal, .contentPadding)
        .onAppear {
            Task {
                await activityViewModel.getAlertPopupListForView()
            }
        }
    }
}

//#Preview {
//    ActivityView(activityViewModel: ActivityViewModel(userUuid: "1234"))
//}

#Preview {
    NavigationStack {
        AlertView(userUuid: "1234")
            .environmentObject(RootViewModel())
            .environmentObject(HomeViewModel(userUuid: "1234"))
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
    }
}
