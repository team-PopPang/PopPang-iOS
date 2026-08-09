import ComposableArchitecture
import DSKit
import SwiftUI

enum PopupPaginationDemoRoute: String, CaseIterable, Hashable {
    case swiftUI
    case uiKit
    case uiKitWillEndDragging
    case uiKitReleaseTrigger
    case popPangListKit
    case uiKitReleaseTriggerPrefetchSample
    case uiKitImagePreparation
    case swiftUIImagePreparation
    case swiftConcurrencyImagePreparation

    var title: String {
        switch self {
        case .swiftUI:
            "SwiftUI"
        case .uiKit:
            "UIKit"
        case .uiKitWillEndDragging:
            "UIKit + WillEndDragging"
        case .uiKitReleaseTrigger:
            "UIKit + Release Trigger"
        case .popPangListKit:
            "PopPangListKit"
        case .uiKitReleaseTriggerPrefetchSample:
            "UIKit + Release Trigger + Picsum"
        case .uiKitImagePreparation:
            "UIKit + Image Preparation"
        case .swiftUIImagePreparation:
            "SwiftUI iOS 17 + Image Preparation"
        case .swiftConcurrencyImagePreparation:
            "Swift Concurrency + Image Preparation"
        }
    }

    var subtitle: String {
        switch self {
        case .swiftUI:
            "ScrollView와 LazyVStack으로 확인합니다."
        case .uiKit:
            "scrollViewDidScroll로 끝에서 0.75 화면 이내를 감지합니다. 현재 스크롤 위치가 threshold 안에 들어오면 다음 페이지를 요청합니다."
        case .uiKitWillEndDragging:
            "scrollViewWillEndDragging으로 예상 위치의 0.75 화면 이내를 미리 감지합니다. 예상 정지 위치를 사용해 빠른 스크롤에서도 다음 페이지를 미리 요청합니다."
        case .uiKitReleaseTrigger:
            "scrollViewWillEndDragging을 주 경로로 사용합니다. scrollViewDidScroll은 감속과 프로그램 이동만 보완합니다."
        case .popPangListKit:
            "List DSL과 내장 pagination 흐름을 확인합니다."
        case .uiKitReleaseTriggerPrefetchSample:
            "Release Trigger와 카드 UI는 유지하고, prefetch 예제의 picsum.photos 이미지만 비교합니다."
        case .uiKitImagePreparation:
            "스크롤 비율로 다음 화면의 이미지를 미리 다운샘플링하고 디코드합니다."
        case .swiftUIImagePreparation:
            "iOS 17 GeometryReader로 스크롤 비율 prefetch를 실험합니다."
        case .swiftConcurrencyImagePreparation:
            "actor와 TaskGroup으로 이미지 선행 처리 동시성을 제한합니다."
        }
    }

    var systemImage: String {
        switch self {
        case .swiftUI:
            "swift"
        case .uiKit:
            "square.stack.3d.up"
        case .uiKitWillEndDragging:
            "scope"
        case .uiKitReleaseTrigger:
            "hand.tap"
        case .popPangListKit:
            "square.grid.2x2"
        case .uiKitReleaseTriggerPrefetchSample:
            "photo.stack"
        case .uiKitImagePreparation:
            "rectangle.on.rectangle.angled"
        case .swiftUIImagePreparation:
            "swiftdata"
        case .swiftConcurrencyImagePreparation:
            "arrow.triangle.2.circlepath"
        }
    }

    var index: String {
        switch self {
        case .swiftUI:
            "01"
        case .uiKit:
            "02"
        case .uiKitWillEndDragging:
            "03"
        case .uiKitReleaseTrigger:
            "04"
        case .popPangListKit:
            "05"
        case .uiKitReleaseTriggerPrefetchSample:
            "06"
        case .uiKitImagePreparation:
            "07"
        case .swiftUIImagePreparation:
            "08"
        case .swiftConcurrencyImagePreparation:
            "09"
        }
    }
}

struct PopupPaginationDemoNavigationView: View {
    let userUuid: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.subWhite.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        LazyVStack(spacing: 14) {
                            ForEach(PopupPaginationDemoRoute.allCases, id: \.self) { route in
                                NavigationLink(value: route) {
                                    PopupPaginationDemoRouteCell(route: route)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Pagination Lab")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PopupPaginationDemoRoute.self) { route in
                PopupPaginationDemoDestinationView(
                    route: route,
                    userUuid: userUuid
                )
            }
        }
    }
}

private extension PopupPaginationDemoNavigationView {
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIX WAYS, ONE CURSOR")
                .font(.scdream(.bold, size: 12))
                .tracking(2.1)
                .foregroundStyle(Color.mainOrange)

            Text("같은 API를\n아홉 가지 리스트로")
                .font(.scdream(.black, size: 30))
                .foregroundStyle(Color.mainBlack)
                .lineSpacing(3)

            Text("각 화면은 독립된 상태로 첫 페이지부터 시작합니다.")
                .font(.scdream(.regular, size: 13))
                .foregroundStyle(Color.mainGray)
                .padding(.top, 2)
        }
        .padding(.top, 30)
        .padding(.bottom, 26)
    }
}

private struct PopupPaginationDemoRouteCell: View {
    let route: PopupPaginationDemoRoute

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(route.index)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.mainOrange)

                Image(systemName: route.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.mainBlack)
            }
            .frame(width: 58, height: 74)
            .background(Color.mainOrange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text(route.title)
                    .font(.scdream(.bold, size: 17))
                    .foregroundStyle(Color.mainBlack)

                Text(route.subtitle)
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mainOrange)
                .frame(width: 30, height: 30)
                .background(Color.mainOrange.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.mainGray.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct PopupPaginationDemoDestinationView: View {
    let route: PopupPaginationDemoRoute
    @State private var store: StoreOf<PopupPaginationDemoFeature>

    init(route: PopupPaginationDemoRoute, userUuid: String) {
        self.route = route
        self._store = State(
            initialValue: Store(
                initialState: PopupPaginationDemoFeature.State(
                    userUuid: userUuid
                )
            ) {
                PopupPaginationDemoFeature()
            }
        )
    }

    @ViewBuilder
    var body: some View {
        switch route {
        case .swiftUI:
            PopupPaginationDemoView(store: store)

        case .uiKit:
            PopupPaginationUIKitDemoView(store: store)

        case .uiKitWillEndDragging:
            PopupPaginationUIKitDemoView(
                store: store,
                paginationTrigger: .projectedTargetOffset
            )

        case .uiKitReleaseTrigger:
            PopupPaginationUIKitDemoView(
                store: store,
                paginationTrigger: .releaseDrivenTargetOffset
            )

        case .popPangListKit:
            PopupPaginationListKitDemoView(store: store)

        case .uiKitReleaseTriggerPrefetchSample:
            PopupPaginationUIKitDemoView(
                store: store,
                paginationTrigger: .releaseDrivenTargetOffset,
                imageSource: .prefetchSample
            )

        case .uiKitImagePreparation:
            PopupPaginationUIKitImagePreparationDemoView(store: store)

        case .swiftUIImagePreparation:
            PopupPaginationSwiftUIImagePreparationDemoView(store: store)

        case .swiftConcurrencyImagePreparation:
            PopupPaginationSwiftConcurrencyImagePreparationDemoView(store: store)
        }
    }
}
