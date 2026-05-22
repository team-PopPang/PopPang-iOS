import AlertFeature
import Core
import HomeFeature
import PopupDetailFeature
import ReviewFeature
import SearchFeature
import SwiftUI

@MainActor
public final class HomeCoordinator: Coordinator<
    HomeFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public func makeRootView() -> some View {
        HomeFeatureView()
            .navigationTitle("Home")
    }

    @ViewBuilder
    public func buildView(for route: HomeFeatureRoute) -> some View {
        switch route {
        case .search:
            SearchFeatureView()
        case .popupDetail:
            PopupDetailFeatureView {
                self.push(.review)
            }
        case .comingSoon:
            ComingSoonFeatureView()
        case .alert:
            AlertFeatureView()
        case .review:
            ReviewFeatureView()
        }
    }
}

private struct ComingSoonFeatureView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.orange.opacity(0.18))
                    .frame(height: 220)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("오픈 예정 팝업")
                                .font(.title2.weight(.bold))
                            Text("V0 ComingPopupDetailView 이식 대상")
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                    }

                VStack(alignment: .leading, spacing: 10) {
                    Text("준비 중 정보")
                        .font(.headline)
                    Text("오픈 예정 상세는 홈의 coming soon 카드에서 진입하고, 일정/브랜드/알림 연결을 함께 제공해야 합니다.")
                        .foregroundStyle(.secondary)
                    Text("현재는 모듈러 라우트와 상세 골격을 먼저 고정한 상태입니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .navigationTitle("Coming Soon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
