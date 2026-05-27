import Core
import MapFeature
import PopupDetailFeature
import ReviewFeature
import SwiftUI

@MainActor
public final class MapCoordinator: Coordinator<
    MapFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    MapBottomSheetRoute
> {
    private var session: MainTabSession
    private var rootView: MapFeatureView!

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
        self.rootView = makeMapRootView(session: session)
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
        self.rootView = makeMapRootView(session: session)
    }

    public func showPopupListSheet() {
        presentBottomSheet(.popupList)
    }

    public func showPopupDetailSheet() {
        presentBottomSheet(.popupDetailSheet)
    }

    public func makeRootView() -> some View {
        rootView
    }

    private func makeMapRootView(session: MainTabSession) -> MapFeatureView {
        MapFeatureView(
            userUuid: session.userUuid,
            onSelectPopup: { [weak self] userUuid, popup in
                self?.push(.popupDetail(userUuid: userUuid, popup: popup))
            }
        )
    }

    @ViewBuilder
    public func buildView(for route: MapFeatureRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                },
                onShowReviews: { [weak self] reviews in
                    self?.push(.reviewDetail(reviews))
                }
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        }
    }

    @ViewBuilder
    public func buildBottomSheet(for route: MapBottomSheetRoute) -> some View {
        MapBottomSheetHost(
            route: route,
            selectedDetent: bottomSheetPosition,
            supportedDetents: supportedBottomSheetDetents,
            onDetentSelected: updateBottomSheetPosition(_:),
            onClose: dismissBottomSheet
        )
    }
}

private struct MapBottomSheetHost: View {
    let route: MapBottomSheetRoute
    let selectedDetent: BottomSheetDetent
    let supportedDetents: [BottomSheetDetent]
    let onDetentSelected: (BottomSheetDetent) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(.secondary)
                .frame(width: 42, height: 6)
                .frame(maxWidth: .infinity)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(supportedDetents, id: \.self) { detent in
                    Button(detentLabel(detent)) {
                        onDetentSelected(detent)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(detent == selectedDetent ? .orange : .gray)
                }
            }

            Button("바텀시트 닫기", action: onClose)
                .buttonStyle(.bordered)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height(for: selectedDetent))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Text(route.id)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(.secondary)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var title: String {
        switch route {
        case .popupList:
            "맵 결과 목록 시트"
        case .popupDetailSheet:
            "맵 팝업 상세 시트"
        }
    }

    private var subtitle: String {
        switch route {
        case .popupList:
            "목록 탐색처럼 맵 안에서 끝나는 흐름은 MapCoordinator가 상태를 직접 소유합니다."
        case .popupDetailSheet:
            "상세 바텀시트도 route 값만 전달하고, 실제 표시 상태는 coordinator가 직접 관리합니다."
        }
    }

    private func detentLabel(_ detent: BottomSheetDetent) -> String {
        switch detent {
        case .hidden:
            "숨김"
        case .fraction(let value):
            "\(Int(value * 100))%"
        case .absolute(let value):
            "\(Int(value))pt"
        }
    }

    private func height(for detent: BottomSheetDetent) -> CGFloat {
        switch detent {
        case .hidden:
            0
        case .fraction(let value):
            UIScreen.main.bounds.height * value
        case .absolute(let value):
            value
        }
    }
}
