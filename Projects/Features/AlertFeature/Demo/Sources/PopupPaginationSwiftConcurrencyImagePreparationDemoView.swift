import ComposableArchitecture
import DSKit
import Foundation
import ImageIO
import SwiftUI
import UIKit

// ImageIO가 만든 뒤에는 MainActor에서 읽기 전용으로만 사용합니다.
private struct PopupPaginationPreparedThumbnail: @unchecked Sendable {
    let image: UIImage
}

private struct PopupPaginationSwiftConcurrencyImageRequest: Sendable {
    let url: URL
    let session: URLSession
    let targetSize: CGSize
    let scale: CGFloat
}

private struct PopupPaginationSwiftConcurrencyImageResult: Sendable {
    let url: URL
    let image: PopupPaginationPreparedThumbnail?
}

private actor PopupPaginationSwiftConcurrencyImagePipeline {
    static let thumbnailSize = CGSize(width: 102, height: 126)

    private static let maximumConcurrentImageTasks = 10
    private static let maximumCachedImageCount = 36

    private let targetSize: CGSize
    private let scale: CGFloat
    private let session: URLSession

    private var cachedImages: [URL: PopupPaginationPreparedThumbnail] = [:]
    private var cachedURLOrder: [URL] = []
    private var queuedURLs: [URL] = []
    private var queuedURLSet = Set<URL>()
    private var activeURLs = Set<URL>()
    private var imageWaiters: [
        URL: [UUID: CheckedContinuation<PopupPaginationPreparedThumbnail?, Never>]
    ] = [:]
    private var workerTask: Task<Void, Never>?
    private var activeGeneration: UUID?

    init(targetSize: CGSize, scale: CGFloat) {
        self.targetSize = targetSize
        self.scale = scale

        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    func prefetch(urls: [URL]) {
        urls.forEach(enqueue)
        startWorkerIfNeeded()
    }

    func image(at url: URL) async -> PopupPaginationPreparedThumbnail? {
        guard !Task.isCancelled else { return nil }

        if let cachedImage = cachedImages[url] {
            return cachedImage
        }

        let waiterID = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                imageWaiters[url, default: [:]][waiterID] = continuation
                enqueue(url)
                startWorkerIfNeeded()
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(url: url, id: waiterID)
            }
        }
    }

    func reset() {
        workerTask?.cancel()
        workerTask = nil
        activeGeneration = nil
        queuedURLs.removeAll()
        queuedURLSet.removeAll()
        activeURLs.removeAll()
        cachedImages.removeAll()
        cachedURLOrder.removeAll()

        let waiters = imageWaiters.values.flatMap { $0.values }
        imageWaiters.removeAll()
        waiters.forEach { $0.resume(returning: nil) }
    }
}

private extension PopupPaginationSwiftConcurrencyImagePipeline {
    func enqueue(_ url: URL) {
        guard cachedImages[url] == nil,
              !queuedURLSet.contains(url),
              !activeURLs.contains(url)
        else {
            return
        }

        queuedURLs.append(url)
        queuedURLSet.insert(url)
    }

    func startWorkerIfNeeded() {
        guard workerTask == nil, !queuedURLs.isEmpty else { return }

        let generation = UUID()
        activeGeneration = generation
        workerTask = Task { [weak self] in
            guard let self else { return }
            await Self.runWorker(pipeline: self, generation: generation)
        }
    }

    func nextRequest(
        for generation: UUID
    ) -> PopupPaginationSwiftConcurrencyImageRequest? {
        guard activeGeneration == generation, !queuedURLs.isEmpty else {
            return nil
        }

        let url = queuedURLs.removeFirst()
        queuedURLSet.remove(url)
        activeURLs.insert(url)

        return PopupPaginationSwiftConcurrencyImageRequest(
            url: url,
            session: session,
            targetSize: targetSize,
            scale: scale
        )
    }

    func complete(
        _ result: PopupPaginationSwiftConcurrencyImageResult,
        for generation: UUID
    ) {
        guard activeGeneration == generation else { return }

        activeURLs.remove(result.url)
        if let image = result.image {
            cache(image, for: result.url)
        }

        let waiters = imageWaiters.removeValue(forKey: result.url).map {
            Array($0.values)
        } ?? []
        waiters.forEach { $0.resume(returning: result.image) }
    }

    func finishWorker(for generation: UUID) {
        guard activeGeneration == generation else { return }

        workerTask = nil
        startWorkerIfNeeded()
    }

    func cancelWaiter(url: URL, id: UUID) {
        let continuation = imageWaiters[url]?.removeValue(forKey: id)
        if imageWaiters[url]?.isEmpty == true {
            imageWaiters.removeValue(forKey: url)
        }
        continuation?.resume(returning: nil)
    }

    func cache(_ image: PopupPaginationPreparedThumbnail, for url: URL) {
        cachedImages[url] = image
        cachedURLOrder.removeAll { $0 == url }
        cachedURLOrder.append(url)

        while cachedURLOrder.count > Self.maximumCachedImageCount {
            let expiredURL = cachedURLOrder.removeFirst()
            cachedImages.removeValue(forKey: expiredURL)
        }
    }

    nonisolated static func runWorker(
        pipeline: PopupPaginationSwiftConcurrencyImagePipeline,
        generation: UUID
    ) async {
        await withTaskGroup(of: PopupPaginationSwiftConcurrencyImageResult.self) { group in
            for _ in 0..<maximumConcurrentImageTasks {
                guard let request = await pipeline.nextRequest(for: generation) else {
                    break
                }

                group.addTask(priority: .utility) {
                    await prepareImage(for: request)
                }
            }

            while let result = await group.next() {
                await pipeline.complete(result, for: generation)

                if let request = await pipeline.nextRequest(for: generation) {
                    group.addTask(priority: .utility) {
                        await prepareImage(for: request)
                    }
                }
            }
        }

        await pipeline.finishWorker(for: generation)
    }

    nonisolated static func prepareImage(
        for request: PopupPaginationSwiftConcurrencyImageRequest
    ) async -> PopupPaginationSwiftConcurrencyImageResult {
        do {
            let (data, response) = try await request.session.data(from: request.url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode
            else {
                return .init(url: request.url, image: nil)
            }

            try Task.checkCancellation()
            let image = downsampledImage(
                from: data,
                targetSize: request.targetSize,
                scale: request.scale
            ).map(PopupPaginationPreparedThumbnail.init(image:))
            return .init(url: request.url, image: image)
        } catch {
            return .init(url: request.url, image: nil)
        }
    }

    nonisolated static func downsampledImage(
        from data: Data,
        targetSize: CGSize,
        scale: CGFloat
    ) -> UIImage? {
        let sourceOptions = [
            kCGImageSourceShouldCache: false,
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let maximumPixelSize = max(targetSize.width, targetSize.height) * scale
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }

        return UIImage(cgImage: image)
    }
}

private enum PopupPaginationSwiftConcurrencyPrefetchPlanner {
    private static let cardStride: CGFloat = 162
    private static let lookAheadViewportRatio: CGFloat = 2.0

    static func urls(
        items: [PopupPaginationItem],
        contentOffsetY: CGFloat,
        viewportHeight: CGFloat
    ) -> [URL] {
        guard viewportHeight > 0, !items.isEmpty else { return [] }

        let firstVisibleIndex = max(Int(contentOffsetY / cardStride), 0)
        let visibleItemCount = max(Int(ceil(viewportHeight / cardStride)), 1)
        let prefetchItemCount = max(
            Int(ceil(viewportHeight * lookAheadViewportRatio / cardStride)),
            1
        )
        let startIndex = min(firstVisibleIndex + visibleItemCount, items.count)
        let endIndex = min(startIndex + prefetchItemCount, items.count)

        guard startIndex < endIndex else { return [] }
        return items[startIndex..<endIndex].compactMap(\.thumbnailURL)
    }
}

struct PopupPaginationSwiftConcurrencyImagePreparationDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var imagePipeline = PopupPaginationSwiftConcurrencyImagePipeline(
        targetSize: PopupPaginationSwiftConcurrencyImagePipeline.thumbnailSize,
        scale: UIScreen.main.scale
    )
    @State private var prefetchTask: Task<Void, Never>?

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: "SWIFT CONCURRENCY",
            store: store
        ) {
            content
        }
        .task {
            store.send(.task)
        }
        .onDisappear {
            prefetchTask?.cancel()
            prefetchTask = nil

            Task {
                await imagePipeline.reset()
            }
        }
    }
}

private extension PopupPaginationSwiftConcurrencyImagePreparationDemoView {
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
            popupList
        }
    }

    var popupList: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    concurrencySummary

                    Color.clear
                        .frame(height: 0)
                        .background {
                            GeometryReader { marker in
                                Color.clear.preference(
                                    key: PopupPaginationSwiftConcurrencyScrollOffsetKey.self,
                                    value: -marker.frame(
                                        in: .named("swift-concurrency-image-scroll")
                                    ).minY
                                )
                            }
                        }

                    LazyVStack(spacing: 12) {
                        ForEach(store.items) { item in
                            PopupPaginationSwiftConcurrencyImageCard(
                                item: item,
                                imagePipeline: imagePipeline
                            )
                            .task(id: item.id) {
                                guard item.id == store.items.last?.id else { return }
                                store.send(.reachedEnd)
                            }
                        }

                        PopupPaginationListFooter(
                            isLoading: store.isLoadingNextPage,
                            errorMessage: store.errorMessage,
                            hasNext: store.hasNext
                        ) {
                            store.send(.retryTapped)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 28)
                }
            }
            .coordinateSpace(name: "swift-concurrency-image-scroll")
            .scrollIndicators(.hidden)
            .onPreferenceChange(PopupPaginationSwiftConcurrencyScrollOffsetKey.self) { offset in
                prefetchImages(
                    contentOffsetY: offset,
                    viewportHeight: proxy.size.height
                )
            }
            .onAppear {
                prefetchImages(contentOffsetY: 0, viewportHeight: proxy.size.height)
            }
        }
    }

    var concurrencySummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mainOrange)

            Text("ACTOR STATE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.mainBlack)

            Text("TASKGROUP x 6")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.mainOrange)

            Spacer(minLength: 0)

            Text("1.25 VIEWPORT")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.mainGray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.mainOrange.opacity(0.08))
    }

    func prefetchImages(contentOffsetY: CGFloat, viewportHeight: CGFloat) {
        let urls = PopupPaginationSwiftConcurrencyPrefetchPlanner.urls(
            items: store.items,
            contentOffsetY: contentOffsetY,
            viewportHeight: viewportHeight
        )

        prefetchTask?.cancel()
        prefetchTask = Task(priority: .utility) { [imagePipeline, urls] in
            guard !Task.isCancelled else { return }
            await imagePipeline.prefetch(urls: urls)
        }
    }
}

private struct PopupPaginationSwiftConcurrencyScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PopupPaginationSwiftConcurrencyImageCard: View {
    let item: PopupPaginationItem
    let imagePipeline: PopupPaginationSwiftConcurrencyImagePipeline

    var body: some View {
        HStack(spacing: 14) {
            PopupPaginationSwiftConcurrencyThumbnail(
                url: item.thumbnailURL,
                imagePipeline: imagePipeline
            )
            .frame(
                width: PopupPaginationSwiftConcurrencyImagePipeline.thumbnailSize.width,
                height: PopupPaginationSwiftConcurrencyImagePipeline.thumbnailSize.height
            )
            .background(Color.mainGray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(item.region)
                        .font(.scdream(.bold, size: 11))
                        .foregroundStyle(Color.mainOrange)

                    Spacer()

                    Image(systemName: item.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            item.isFavorited ? Color.mainOrange : Color.mainGray
                        )
                }

                Text(item.name)
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.mainBlack)
                    .lineLimit(2)
                    .padding(.top, 8)

                Spacer()

                Text("\(item.startDate) - \(item.endDate)")
                    .font(.scdream(.regular, size: 11))
                    .foregroundStyle(Color.mainGray)
                    .lineLimit(1)

                Text(item.popupUuid)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.mainGray.opacity(0.7))
                    .lineLimit(1)
                    .padding(.top, 5)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mainGray.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct PopupPaginationSwiftConcurrencyThumbnail: View {
    let url: URL?
    let imagePipeline: PopupPaginationSwiftConcurrencyImagePipeline

    @State private var preparedThumbnail: PopupPaginationPreparedThumbnail?
    @State private var didFail = false

    var body: some View {
        Group {
            if let preparedThumbnail {
                Image(uiImage: preparedThumbnail.image)
                    .resizable()
                    .scaledToFill()
            } else if didFail || url == nil {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.mainGray)
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            preparedThumbnail = nil
            didFail = false

            guard let url else { return }
            let loadedThumbnail = await imagePipeline.image(at: url)
            guard !Task.isCancelled else { return }

            preparedThumbnail = loadedThumbnail
            didFail = loadedThumbnail == nil
        }
    }
}
