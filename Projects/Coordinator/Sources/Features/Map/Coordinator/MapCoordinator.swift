import Core
import MapFeature
import SwiftUI

@MainActor
public final class MapCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    MapBottomSheetRoute
> {
    public func showPopupListSheet() {
        presentBottomSheet(.popupList)
    }

    public func showPopupDetailSheet() {
        presentBottomSheet(.popupDetail)
    }

    public func makeRootView() -> some View {
        MapFeatureView()
            .navigationTitle("Map")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
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
        case .popupDetail:
            "맵 팝업 상세 시트"
        }
    }

    private var subtitle: String {
        switch route {
        case .popupList:
            "목록 탐색처럼 맵 안에서 끝나는 흐름은 MapCoordinator가 상태를 직접 소유합니다."
        case .popupDetail:
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
