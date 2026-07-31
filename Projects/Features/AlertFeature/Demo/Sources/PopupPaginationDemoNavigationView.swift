import ComposableArchitecture
import DSKit
import SwiftUI

enum PopupPaginationDemoRoute: String, CaseIterable, Hashable {
    case swiftUI
    case uiKit
    case popPangListKit

    var title: String {
        switch self {
        case .swiftUI:
            "SwiftUI"
        case .uiKit:
            "UIKit"
        case .popPangListKit:
            "PopPangListKit"
        }
    }

    var subtitle: String {
        switch self {
        case .swiftUI:
            "ScrollView와 LazyVStack으로 확인합니다."
        case .uiKit:
            "Compositional, Diffable, Prefetch를 직접 연결합니다."
        case .popPangListKit:
            "List DSL과 내장 pagination 흐름을 확인합니다."
        }
    }

    var systemImage: String {
        switch self {
        case .swiftUI:
            "swift"
        case .uiKit:
            "square.stack.3d.up"
        case .popPangListKit:
            "square.grid.2x2"
        }
    }

    var index: String {
        switch self {
        case .swiftUI:
            "01"
        case .uiKit:
            "02"
        case .popPangListKit:
            "03"
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
            Text("THREE WAYS, ONE CURSOR")
                .font(.scdream(.bold, size: 12))
                .tracking(2.1)
                .foregroundStyle(Color.mainOrange)

            Text("같은 API를\n세 가지 리스트로")
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

        case .popPangListKit:
            PopupPaginationListKitDemoView(store: store)
        }
    }
}
