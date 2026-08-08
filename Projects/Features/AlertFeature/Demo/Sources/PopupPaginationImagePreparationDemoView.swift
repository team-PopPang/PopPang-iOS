import ComposableArchitecture
import DSKit
import Foundation
import ImageIO
import Kingfisher
import SwiftUI
import UIKit

enum PopupPaginationImageExperimentMode: String, CaseIterable, Identifiable {
    case imageIOPrepared
    case kingfisherVisible
    case kingfisherPrefetch

    var id: Self { self }

    var title: String {
        switch self {
        case .imageIOPrepared:
            "ImageIO"
        case .kingfisherVisible:
            "KF 표시"
        case .kingfisherPrefetch:
            "KF 선행"
        }
    }

    var implementationTitle: String {
        switch self {
        case .imageIOPrepared:
            "IMAGEIO PREPARED"
        case .kingfisherVisible:
            "KINGFISHER VISIBLE"
        case .kingfisherPrefetch:
            "KINGFISHER PREPARED"
        }
    }
}

@MainActor
final class PopupPaginationImageExperimentSession {
    static let thumbnailSize = CGSize(width: 102, height: 126)

    private let imageIOPipeline = PopupPaginationImageIOPipeline(
        targetSize: thumbnailSize,
        scale: UIScreen.main.scale
    )
    let kingfisherCache = ImageCache(name: "com.poppang.demo.alert.image-lab")
    private var activeKingfisherPrefetcher: ImagePrefetcher?
    private var activeKingfisherPrefetchID: UUID?
    private var pendingKingfisherURLs: [URL] = []
    private var requestedKingfisherURLs = Set<URL>()

    var kingfisherOptions: KingfisherOptionsInfo {
        [
            .processor(DownsamplingImageProcessor(size: Self.thumbnailSize)),
            .scaleFactor(UIScreen.main.scale),
            .targetCache(kingfisherCache),
            .cacheMemoryOnly,
            .backgroundDecode,
        ]
    }

    func prefetch(
        urls: [URL],
        mode: PopupPaginationImageExperimentMode
    ) {
        switch mode {
        case .imageIOPrepared:
            imageIOPipeline.prefetch(urls: urls)

        case .kingfisherVisible:
            break

        case .kingfisherPrefetch:
            prefetchWithKingfisher(urls: urls)
        }
    }

    func loadImage(
        at url: URL,
        completion: @escaping PopupPaginationImageIOPipeline.ImageCompletion
    ) -> UUID {
        imageIOPipeline.loadImage(at: url, completion: completion)
    }

    func cancelImageLoad(_ id: UUID) {
        imageIOPipeline.cancelImageLoad(id)
    }

    func reset() {
        activeKingfisherPrefetcher?.stop()
        activeKingfisherPrefetcher = nil
        activeKingfisherPrefetchID = nil
        pendingKingfisherURLs.removeAll()
        requestedKingfisherURLs.removeAll()
        kingfisherCache.clearMemoryCache()
        imageIOPipeline.reset()
    }
}

private extension PopupPaginationImageExperimentSession {
    func prefetchWithKingfisher(urls: [URL]) {
        let candidates = urls.filter { requestedKingfisherURLs.insert($0).inserted }
        guard !candidates.isEmpty else { return }

        pendingKingfisherURLs.append(contentsOf: candidates)
        startNextKingfisherPrefetchIfNeeded()
    }

    func startNextKingfisherPrefetchIfNeeded() {
        guard activeKingfisherPrefetcher == nil, !pendingKingfisherURLs.isEmpty else {
            return
        }

        let urls = Array(pendingKingfisherURLs.prefix(6))
        pendingKingfisherURLs.removeFirst(urls.count)
        let id = UUID()
        let prefetcher = ImagePrefetcher(
            urls: urls,
            options: kingfisherOptions,
            completionHandler: { [weak self] _, _, _ in
                Task { @MainActor in
                    self?.completeKingfisherPrefetch(id)
                }
            }
        )

        // Keep the comparison aligned with the serial ImageIO decode queue.
        prefetcher.maxConcurrentDownloads = 1
        activeKingfisherPrefetchID = id
        activeKingfisherPrefetcher = prefetcher
        prefetcher.start()
    }

    func completeKingfisherPrefetch(_ id: UUID) {
        guard activeKingfisherPrefetchID == id else { return }

        activeKingfisherPrefetchID = nil
        activeKingfisherPrefetcher = nil
        startNextKingfisherPrefetchIfNeeded()
    }
}

final class PopupPaginationImageIOPipeline: @unchecked Sendable {
    typealias ImageCompletion = @MainActor (UIImage?) -> Void

    private struct PendingLoad {
        let task: URLSessionDataTask
        var completions: [UUID: ImageCompletion]
    }

    private let targetSize: CGSize
    private let scale: CGFloat
    private let session: URLSession
    private let decodeQueue = DispatchQueue(
        label: "com.poppang.demo.alert.image-lab.decode",
        qos: .utility
    )
    private let lock = NSLock()
    private let maximumCachedImageCount = 36

    private var cachedImages: [URL: UIImage] = [:]
    private var cachedURLOrder: [URL] = []
    private var pendingLoads: [URL: PendingLoad] = [:]
    private var loadURLsByID: [UUID: URL] = [:]

    init(targetSize: CGSize, scale: CGFloat) {
        self.targetSize = targetSize
        self.scale = scale

        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    func prefetch(urls: [URL]) {
        var tasksToResume: [URLSessionDataTask] = []

        lock.lock()
        for url in urls where cachedImages[url] == nil && pendingLoads[url] == nil {
            let task = makeTask(for: url)
            pendingLoads[url] = PendingLoad(task: task, completions: [:])
            tasksToResume.append(task)
        }
        lock.unlock()

        tasksToResume.forEach { $0.resume() }
    }

    @discardableResult
    func loadImage(
        at url: URL,
        completion: @escaping ImageCompletion
    ) -> UUID {
        let id = UUID()
        var cachedImage: UIImage?
        var taskToResume: URLSessionDataTask?

        lock.lock()
        if let image = cachedImages[url] {
            cachedImage = image
        } else if var pendingLoad = pendingLoads[url] {
            pendingLoad.completions[id] = completion
            pendingLoads[url] = pendingLoad
            loadURLsByID[id] = url
        } else {
            let task = makeTask(for: url)
            pendingLoads[url] = PendingLoad(
                task: task,
                completions: [id: completion]
            )
            loadURLsByID[id] = url
            taskToResume = task
        }
        lock.unlock()

        if let cachedImage {
            Task { @MainActor in
                completion(cachedImage)
            }
        } else {
            taskToResume?.resume()
        }

        return id
    }

    func cancelImageLoad(_ id: UUID) {
        lock.lock()
        if let url = loadURLsByID.removeValue(forKey: id),
           var pendingLoad = pendingLoads[url]
        {
            pendingLoad.completions.removeValue(forKey: id)
            pendingLoads[url] = pendingLoad
        }
        lock.unlock()
    }

    func reset() {
        let tasks: [URLSessionDataTask]

        lock.lock()
        tasks = pendingLoads.values.map(\.task)
        pendingLoads.removeAll()
        loadURLsByID.removeAll()
        cachedImages.removeAll()
        cachedURLOrder.removeAll()
        lock.unlock()

        tasks.forEach { $0.cancel() }
    }
}

private extension PopupPaginationImageIOPipeline {
    func makeTask(for url: URL) -> URLSessionDataTask {
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }

            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let data
            else {
                self.complete(url: url, image: nil)
                return
            }

            decodeQueue.async { [weak self] in
                guard let self else { return }
                let image = Self.downsampledImage(
                    from: data,
                    targetSize: self.targetSize,
                    scale: self.scale
                )
                self.complete(url: url, image: image)
            }
        }
    }

    func complete(url: URL, image: UIImage?) {
        let completions: [ImageCompletion]

        lock.lock()
        let pendingLoad = pendingLoads.removeValue(forKey: url)
        completions = pendingLoad.map { Array($0.completions.values) } ?? []
        pendingLoad?.completions.keys.forEach { loadURLsByID.removeValue(forKey: $0) }

        if let image {
            cache(image, for: url)
        }
        lock.unlock()

        guard !completions.isEmpty else { return }
        Task { @MainActor in
            completions.forEach { $0(image) }
        }
    }

    func cache(_ image: UIImage, for url: URL) {
        cachedImages[url] = image
        cachedURLOrder.removeAll { $0 == url }
        cachedURLOrder.append(url)

        while cachedURLOrder.count > maximumCachedImageCount {
            let expiredURL = cachedURLOrder.removeFirst()
            cachedImages.removeValue(forKey: expiredURL)
        }
    }

    static func downsampledImage(
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

private enum PopupPaginationScrollRatioPrefetchPlanner {
    private static let cardStride: CGFloat = 162
    private static let lookAheadViewportRatio: CGFloat = 1.25

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

private struct PopupPaginationImageExperimentPicker: View {
    @Binding var mode: PopupPaginationImageExperimentMode

    var body: some View {
        Picker("이미지 실험 방식", selection: $mode) {
            ForEach(PopupPaginationImageExperimentMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

struct PopupPaginationSwiftUIImagePreparationDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var mode: PopupPaginationImageExperimentMode = .imageIOPrepared
    @State private var imageSession = PopupPaginationImageExperimentSession()

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: "SWIFTUI iOS 17",
            store: store
        ) {
            VStack(spacing: 0) {
                PopupPaginationImageExperimentPicker(mode: $mode)
                content
            }
        }
        .task {
            store.send(.task)
        }
        .onChange(of: mode) { _, _ in
            imageSession.reset()
        }
    }
}

private extension PopupPaginationSwiftUIImagePreparationDemoView {
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
                    Color.clear
                        .frame(height: 0)
                        .background {
                            GeometryReader { marker in
                                Color.clear.preference(
                                    key: PopupPaginationScrollOffsetPreferenceKey.self,
                                    value: -marker.frame(
                                        in: .named("image-preparation-scroll")
                                    ).minY
                                )
                            }
                        }

                    LazyVStack(spacing: 12) {
                        ForEach(store.items) { item in
                            PopupPaginationImageExperimentCard(
                                item: item,
                                mode: mode,
                                imageSession: imageSession
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
            .coordinateSpace(name: "image-preparation-scroll")
            .scrollIndicators(.hidden)
            .onPreferenceChange(PopupPaginationScrollOffsetPreferenceKey.self) { offset in
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

    func prefetchImages(contentOffsetY: CGFloat, viewportHeight: CGFloat) {
        let urls = PopupPaginationScrollRatioPrefetchPlanner.urls(
            items: store.items,
            contentOffsetY: contentOffsetY,
            viewportHeight: viewportHeight
        )
        imageSession.prefetch(urls: urls, mode: mode)
    }
}

private struct PopupPaginationScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PopupPaginationImageExperimentCard: View {
    let item: PopupPaginationItem
    let mode: PopupPaginationImageExperimentMode
    let imageSession: PopupPaginationImageExperimentSession

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
                .frame(
                    width: PopupPaginationImageExperimentSession.thumbnailSize.width,
                    height: PopupPaginationImageExperimentSession.thumbnailSize.height
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

    @ViewBuilder
    private var thumbnail: some View {
        switch mode {
        case .imageIOPrepared:
            PopupPaginationImageIOThumbnail(
                url: item.thumbnailURL,
                imageSession: imageSession
            )

        case .kingfisherVisible, .kingfisherPrefetch:
            PopupPaginationKingfisherThumbnail(
                url: item.thumbnailURL,
                imageSession: imageSession
            )
        }
    }
}

private struct PopupPaginationImageIOThumbnail: View {
    let url: URL?
    let imageSession: PopupPaginationImageExperimentSession

    @State private var image: UIImage?
    @State private var loadID: UUID?
    @State private var requestGeneration = UUID()
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didFail || url == nil {
                fallbackImage
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: startLoading)
        .onDisappear(perform: cancelLoading)
        .onChange(of: url) { _, _ in
            cancelLoading()
            image = nil
            didFail = false
            startLoading()
        }
    }

    private var fallbackImage: some View {
        Image(systemName: "photo")
            .font(.system(size: 22, weight: .light))
            .foregroundStyle(Color.mainGray)
    }

    private func startLoading() {
        guard loadID == nil, image == nil, !didFail, let url else { return }

        let generation = UUID()
        requestGeneration = generation
        loadID = imageSession.loadImage(at: url) { loadedImage in
            guard requestGeneration == generation else { return }
            image = loadedImage
            didFail = loadedImage == nil
            loadID = nil
        }
    }

    private func cancelLoading() {
        requestGeneration = UUID()
        guard let loadID else { return }
        imageSession.cancelImageLoad(loadID)
        self.loadID = nil
    }
}

private struct PopupPaginationKingfisherThumbnail: View {
    let url: URL?
    let imageSession: PopupPaginationImageExperimentSession

    var body: some View {
        if let url {
            KFImage(url)
                .setProcessor(
                    DownsamplingImageProcessor(
                        size: PopupPaginationImageExperimentSession.thumbnailSize
                    )
                )
                .scaleFactor(UIScreen.main.scale)
                .targetCache(imageSession.kingfisherCache)
                .cacheMemoryOnly()
                .backgroundDecode()
                .placeholder {
                    ProgressView()
                }
                .onFailureView {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color.mainGray)
                }
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.mainGray)
        }
    }
}

struct PopupPaginationUIKitImagePreparationDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var mode: PopupPaginationImageExperimentMode = .imageIOPrepared
    @State private var imageSession = PopupPaginationImageExperimentSession()

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: "UIKIT IMAGE LAB",
            store: store
        ) {
            VStack(spacing: 0) {
                PopupPaginationImageExperimentPicker(mode: $mode)
                content
            }
        }
        .task {
            store.send(.task)
        }
        .onChange(of: mode) { _, _ in
            imageSession.reset()
        }
    }
}

private extension PopupPaginationUIKitImagePreparationDemoView {
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
            PopupPaginationImagePreparationUIKitCollection(
                items: store.items,
                canLoadNextPage: store.hasNext
                    && !store.isRequesting
                    && store.errorMessage == nil,
                mode: mode,
                imageSession: imageSession
            ) {
                store.send(.reachedEnd)
            }
        }
    }
}

private struct PopupPaginationImagePreparationUIKitCollection: UIViewControllerRepresentable {
    let items: [PopupPaginationItem]
    let canLoadNextPage: Bool
    let mode: PopupPaginationImageExperimentMode
    let imageSession: PopupPaginationImageExperimentSession
    let onReachedEnd: () -> Void

    func makeUIViewController(context: Context) -> PopupPaginationImagePreparationViewController {
        PopupPaginationImagePreparationViewController(
            mode: mode,
            imageSession: imageSession,
            onReachedEnd: onReachedEnd
        )
    }

    func updateUIViewController(
        _ viewController: PopupPaginationImagePreparationViewController,
        context: Context
    ) {
        viewController.update(
            items: items,
            canLoadNextPage: canLoadNextPage,
            mode: mode
        )
    }
}

@MainActor
private final class PopupPaginationImagePreparationViewController: UIViewController {
    private let imageSession: PopupPaginationImageExperimentSession
    private let onReachedEnd: () -> Void
    private let collectionView: UICollectionView
    private var items: [PopupPaginationItem] = []
    private var mode: PopupPaginationImageExperimentMode
    private var canLoadNextPage = false

    init(
        mode: PopupPaginationImageExperimentMode,
        imageSession: PopupPaginationImageExperimentSession,
        onReachedEnd: @escaping () -> Void
    ) {
        self.mode = mode
        self.imageSession = imageSession
        self.onReachedEnd = onReachedEnd
        self.collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(Color.subWhite)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PopupPaginationImagePreparationCollectionCell.self,
            forCellWithReuseIdentifier: PopupPaginationImagePreparationCollectionCell.reuseIdentifier
        )

        view.backgroundColor = UIColor(Color.subWhite)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func update(
        items: [PopupPaginationItem],
        canLoadNextPage: Bool,
        mode: PopupPaginationImageExperimentMode
    ) {
        self.mode = mode
        self.items = items
        self.canLoadNextPage = canLoadNextPage
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        prefetchImages(contentOffsetY: collectionView.contentOffset.y)
    }
}

private extension PopupPaginationImagePreparationViewController {
    static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(150)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: itemSize,
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 4,
                leading: 20,
                bottom: 28,
                trailing: 20
            )
            return section
        }
    }

    func prefetchImages(contentOffsetY: CGFloat) {
        let urls = PopupPaginationScrollRatioPrefetchPlanner.urls(
            items: items,
            contentOffsetY: contentOffsetY,
            viewportHeight: collectionView.bounds.height
        )
        imageSession.prefetch(urls: urls, mode: mode)
    }

    func loadNextPageIfNeeded(contentOffsetY: CGFloat) {
        guard canLoadNextPage,
              collectionView.contentSize.height > collectionView.bounds.height
        else {
            return
        }

        let visibleBottom = contentOffsetY + collectionView.bounds.height
        let triggerOffset = collectionView.contentSize.height - collectionView.bounds.height * 0.75
        guard visibleBottom >= triggerOffset else { return }

        canLoadNextPage = false
        onReachedEnd()
    }
}

extension PopupPaginationImagePreparationViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PopupPaginationImagePreparationCollectionCell.reuseIdentifier,
            for: indexPath
        )

        guard let cell = cell as? PopupPaginationImagePreparationCollectionCell else {
            return cell
        }

        cell.configure(
            with: items[indexPath.item],
            mode: mode,
            imageSession: imageSession
        )
        return cell
    }
}

extension PopupPaginationImagePreparationViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        prefetchImages(contentOffsetY: scrollView.contentOffset.y)
        loadNextPageIfNeeded(contentOffsetY: scrollView.contentOffset.y)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetOffsetY = targetContentOffset.pointee.y
        prefetchImages(contentOffsetY: targetOffsetY)
        loadNextPageIfNeeded(contentOffsetY: targetOffsetY)
    }
}

@MainActor
private final class PopupPaginationImagePreparationCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "PopupPaginationImagePreparationCollectionCell"

    private let thumbnailImageView = UIImageView()
    private let regionLabel = UILabel()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let uuidLabel = UILabel()
    private var imageSession: PopupPaginationImageExperimentSession?
    private var imageLoadID: UUID?
    private var imageLoadGeneration = UUID()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageLoad()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = Self.placeholderImage
        imageSession = nil
    }

    func configure(
        with item: PopupPaginationItem,
        mode: PopupPaginationImageExperimentMode,
        imageSession: PopupPaginationImageExperimentSession
    ) {
        cancelImageLoad()
        thumbnailImageView.kf.cancelDownloadTask()
        self.imageSession = imageSession
        thumbnailImageView.image = Self.placeholderImage
        regionLabel.text = item.region
        nameLabel.text = item.name
        dateLabel.text = "\(item.startDate) - \(item.endDate)"
        uuidLabel.text = item.popupUuid

        guard let url = item.thumbnailURL else { return }

        switch mode {
        case .imageIOPrepared:
            let generation = UUID()
            imageLoadGeneration = generation
            imageLoadID = imageSession.loadImage(at: url) { [weak self] image in
                guard let self, imageLoadGeneration == generation else { return }
                thumbnailImageView.image = image ?? Self.placeholderImage
                imageLoadID = nil
            }

        case .kingfisherVisible, .kingfisherPrefetch:
            thumbnailImageView.kf.setImage(
                with: url,
                placeholder: Self.placeholderImage,
                options: imageSession.kingfisherOptions
            )
        }
    }
}

private extension PopupPaginationImagePreparationCollectionCell {
    static let placeholderImage = UIImage(systemName: "photo")

    func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(Color.mainGray.opacity(0.12)).cgColor
        clipsToBounds = true

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        thumbnailImageView.layer.cornerCurve = .continuous
        thumbnailImageView.backgroundColor = UIColor(Color.mainGray.opacity(0.08))
        thumbnailImageView.tintColor = UIColor(Color.mainGray)

        regionLabel.font = .scdream(.bold, size: 11)
        regionLabel.textColor = UIColor(Color.mainOrange)

        nameLabel.font = .scdream(.bold, size: 15)
        nameLabel.textColor = UIColor(Color.mainBlack)
        nameLabel.numberOfLines = 2

        dateLabel.font = .scdream(.regular, size: 11)
        dateLabel.textColor = UIColor(Color.mainGray)

        uuidLabel.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
        uuidLabel.textColor = UIColor(Color.mainGray.opacity(0.7))
    }

    func configureLayout() {
        let flexibleSpacer = UIView()
        flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)

        let detailStack = UIStackView(arrangedSubviews: [
            regionLabel,
            nameLabel,
            flexibleSpacer,
            dateLabel,
            uuidLabel,
        ])
        detailStack.axis = .vertical
        detailStack.alignment = .fill
        detailStack.spacing = 5

        let contentStack = UIStackView(arrangedSubviews: [
            thumbnailImageView,
            detailStack,
        ])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.alignment = .fill
        contentStack.spacing = 14

        contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(
                equalToConstant: PopupPaginationImageExperimentSession.thumbnailSize.width
            ),
            thumbnailImageView.heightAnchor.constraint(
                equalToConstant: PopupPaginationImageExperimentSession.thumbnailSize.height
            ),
        ])
    }

    func cancelImageLoad() {
        imageLoadGeneration = UUID()
        guard let imageLoadID else { return }
        imageSession?.cancelImageLoad(imageLoadID)
        self.imageLoadID = nil
    }
}
