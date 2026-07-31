import ComposableArchitecture
import Kingfisher
import PopPangListKit
import SwiftUI
import UIKit

struct PopupPaginationListKitDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var imagePrefetcher = PopupPaginationImagePrefetcher()

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
                    remoteImagePrefetcher: imagePrefetcher
                ),
            ]
        ) {
            PopPangListKit.Section(id: "popups") {
                for item in store.items {
                    PopPangListKit.Cell(
                        id: item.id,
                        component: PopupPaginationListKitCardComponent(
                            item: item
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
        content.configure(with: item)
    }
}

private final class PopupPaginationImagePrefetcher:
    RemoteImagePrefetching,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var tasks: [UUID: DownloadTask] = [:]

    func prefetchImage(url: URL) -> UUID? {
        let id = UUID()
        guard let task = KingfisherManager.shared.retrieveImage(
            with: url,
            options: [.cacheOriginalImage],
            completionHandler: { [weak self] _ in
                _ = self?.removeTask(id: id)
            }
        ) else {
            return nil
        }

        lock.lock()
        tasks[id] = task
        lock.unlock()
        return id
    }

    func cancelTask(uuid: UUID) {
        removeTask(id: uuid)?.cancel()
    }

    deinit {
        lock.lock()
        let activeTasks = Array(tasks.values)
        tasks.removeAll()
        lock.unlock()
        activeTasks.forEach { $0.cancel() }
    }

    private func removeTask(id: UUID) -> DownloadTask? {
        lock.lock()
        defer { lock.unlock() }
        return tasks.removeValue(forKey: id)
    }
}
