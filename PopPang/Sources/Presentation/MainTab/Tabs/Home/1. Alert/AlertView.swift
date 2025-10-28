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
            // 커스텀 좌측
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("backButton")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.subBlack)
                }
            }
            
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
        .navigationBarBackButtonHidden(true)
        .background(EnableSwipeBackGesture())  // 제스처 복원
    }
}

#Preview {
    NavigationStack {
        AlertView(userUuid: "1234")
            .environmentObject(HomeViewModel(userUuid: "1234"))
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

// MARK: - 제스처 복원
struct EnableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            controller.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            controller.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


