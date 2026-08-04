import ComposableArchitecture
import PopPangListKit
import SwiftUI
import UIKit

struct PopupPaginationListKitDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var imagePipeline = PopupPaginationImagePipeline()

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: "LISTKIT",
            store: store
        ) {
            content
        }
        .task {
            store.send(.task)
        }
    }
}

private extension PopupPaginationListKitDemoView {
    @ViewBuilder
    var content: some View {
        if store.isInitialLoading {
            PopupPaginationLoadingState()
        } else if !store.hasStarted {
            PopupPaginationEmptyState(
                title: "데모 UUID를 확인해 주세요",
                description: "AlertFeatureDemo.xcconfig의 UUID가 비어 있습니다."
            )
        } else if store.items.isEmpty, let errorMessage = store.errorMessage {
            PopupPaginationErrorState(message: errorMessage) {
                store.send(.retryTapped)
            }
        } else if store.items.isEmpty {
            PopupPaginationEmptyState(
                title: "표시할 팝업이 없습니다",
                description: "API 응답의 items가 비어 있습니다."
            )
        } else {
            VStack(spacing: 0) {
                popupList

                PopupPaginationListFooter(
                    isLoading: store.isLoadingNextPage,
                    errorMessage: store.errorMessage,
                    hasNext: store.hasNext
                ) {
                    store.send(.retryTapped)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    var popupList: some View {
        PopPangList(
            prefetchingPlugins: [
                RemoteImagePrefetchingPlugin(
                    remoteImagePrefetcher: imagePipeline
                ),
            ]
        ) {
            PopPangListKit.Section(id: "popups") {
                for item in store.items {
                    PopPangListKit.Cell(
                        id: item.id,
                        component: PopupPaginationListKitCardComponent(
                            item: item,
                            imagePipeline: imagePipeline
                        )
                    )
                }
            }
            .withSectionLayout(
                VerticalLayout(spacing: 12)
                    .insets(
                        NSDirectionalEdgeInsets(
                            top: 4,
                            leading: 20,
                            bottom: 28,
                            trailing: 20
                        )
                    )
            )
        }
        .onReachEnd(
            offsetFromEnd: .relativeToContainerSize(multiplier: 0.75)
        ) { _ in
            store.send(.reachedEnd)
        }
    }
}

private struct PopupPaginationListKitCardComponent:
    Component,
    ComponentRemoteImagePrefetchable
{
    let item: PopupPaginationItem
    let imagePipeline: PopupPaginationImagePipeline

    var layoutMode: ContentLayoutMode {
        .flexibleHeight(estimatedHeight: 150)
    }

    var remoteImageURLs: [URL] {
        item.thumbnailURL.map { [$0] } ?? []
    }

    @MainActor
    func renderContent(coordinator: Void) -> PopupPaginationUIKitCardView {
        PopupPaginationUIKitCardView()
    }

    @MainActor
    func render(
        in content: PopupPaginationUIKitCardView,
        coordinator: Void
    ) {
        content.configure(
            with: item,
            imagePipeline: imagePipeline
        )
    }
}

extension PopupPaginationImagePipeline: RemoteImagePrefetching {
    func prefetchImage(url: URL) -> UUID? {
        prefetchImage(at: url)
    }

    func cancelTask(uuid: UUID) {
        cancelPrefetch(uuid)
    }
}
