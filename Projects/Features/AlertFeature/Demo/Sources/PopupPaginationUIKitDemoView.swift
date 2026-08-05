import ComposableArchitecture
import DSKit
import SwiftUI
import UIKit

enum PopupPaginationUIKitPaginationTrigger {
    case didScroll
    case projectedTargetOffset
    case releaseDrivenTargetOffset

    var implementationTitle: String {
        switch self {
        case .didScroll:
            "UIKIT"
        case .projectedTargetOffset:
            "UIKIT PREDICT"
        case .releaseDrivenTargetOffset:
            "UIKIT RELEASE"
        }
    }
}

enum PopupPaginationUIKitImageSource {
    case popPang
    case prefetchSample

    func url(
        for item: PopupPaginationItem,
        index: Int
    ) -> URL? {
        switch self {
        case .popPang:
            item.thumbnailURL

        case .prefetchSample:
            // 예제 호스트로 팝업 UUID를 보내지 않도록 목록 순번을 고정 seed로 사용한다.
            URL(
                string: "https://picsum.photos/seed/basic-prefetch-"
                    + String(index)
                    + "/600/400"
            )
        }
    }
}

struct PopupPaginationUIKitDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var imagePipeline = PopupPaginationImagePipeline()
    let paginationTrigger: PopupPaginationUIKitPaginationTrigger
    let imageSource: PopupPaginationUIKitImageSource

    init(
        store: StoreOf<PopupPaginationDemoFeature>,
        paginationTrigger: PopupPaginationUIKitPaginationTrigger = .didScroll,
        imageSource: PopupPaginationUIKitImageSource = .popPang
    ) {
        self.store = store
        self.paginationTrigger = paginationTrigger
        self.imageSource = imageSource
    }

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: paginationTrigger.implementationTitle,
            store: store
        ) {
            content
        }
        .task {
            store.send(.task)
        }
    }
}

private extension PopupPaginationUIKitDemoView {
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
                PopupPaginationUIKitCollectionView(
                    items: store.items,
                    canLoadNextPage: store.hasNext
                        && !store.isRequesting
                        && store.errorMessage == nil,
                    imagePipeline: imagePipeline,
                    paginationTrigger: paginationTrigger,
                    imageSource: imageSource
                ) {
                    store.send(.reachedEnd)
                }

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
}

private struct PopupPaginationUIKitCollectionView: UIViewControllerRepresentable {
    let items: [PopupPaginationItem]
    let canLoadNextPage: Bool
    let imagePipeline: PopupPaginationImagePipeline
    let paginationTrigger: PopupPaginationUIKitPaginationTrigger
    let imageSource: PopupPaginationUIKitImageSource
    let onReachedEnd: () -> Void

    func makeUIViewController(context: Context) -> PopupPaginationUIKitViewController {
        PopupPaginationUIKitViewController(
            imagePipeline: imagePipeline,
            paginationTrigger: paginationTrigger,
            imageSource: imageSource,
            onReachedEnd: onReachedEnd
        )
    }

    func updateUIViewController(
        _ viewController: PopupPaginationUIKitViewController,
        context: Context
    ) {
        viewController.update(
            items: items,
            canLoadNextPage: canLoadNextPage
        )
    }
}

@MainActor
private final class PopupPaginationUIKitViewController: UIViewController {
    private enum Section: Hashable {
        case popups
    }

    private let onReachedEnd: () -> Void
    private let imagePipeline: PopupPaginationImagePipeline
    private let paginationTrigger: PopupPaginationUIKitPaginationTrigger
    private let imageSource: PopupPaginationUIKitImageSource
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, String>!
    private var itemsByID: [String: PopupPaginationItem] = [:]
    private var imageURLsByID: [String: URL] = [:]
    private var prefetchTokens: [String: UUID] = [:]
    private var canLoadNextPage = false

    init(
        imagePipeline: PopupPaginationImagePipeline,
        paginationTrigger: PopupPaginationUIKitPaginationTrigger,
        imageSource: PopupPaginationUIKitImageSource,
        onReachedEnd: @escaping () -> Void
    ) {
        self.imagePipeline = imagePipeline
        self.paginationTrigger = paginationTrigger
        self.imageSource = imageSource
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
        configureCollectionView()
        configureDataSource()
    }

    func update(
        items: [PopupPaginationItem],
        canLoadNextPage: Bool
    ) {
        self.itemsByID = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, $0) }
        )
        self.imageURLsByID = Dictionary(
            uniqueKeysWithValues: items.enumerated().compactMap { index, item in
                imageSource.url(for: item, index: index).map { (item.id, $0) }
            }
        )
        self.canLoadNextPage = canLoadNextPage

        let identifiers = items.map(\.id)
        guard dataSource.snapshot().itemIdentifiers != identifiers else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.popups])
        snapshot.appendItems(identifiers, toSection: .popups)
        dataSource.apply(
            snapshot,
            animatingDifferences: !dataSource.snapshot().itemIdentifiers.isEmpty
        )
    }

    deinit {
        prefetchTokens.values.forEach { imagePipeline.cancelPrefetch($0) }
    }
}

private extension PopupPaginationUIKitViewController {
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

    func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(Color.subWhite)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.prefetchDataSource = self

        view.backgroundColor = UIColor(Color.subWhite)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// Item ID를 기준으로 셀을 구성하는 Diffable Data Source를 연결합니다.
    ///
    /// snapshot에는 Item ID만 저장하고, 셀을 만들 때 `itemsByID`에서
    /// 실제 팝업 모델을 찾아 카드와 표시용 이미지 요청을 구성합니다.
    func configureDataSource() {
        let registration = UICollectionView.CellRegistration<
            PopupPaginationCollectionViewCell,
            String
        > { [weak self] cell, _, itemID in
            guard let self, let item = itemsByID[itemID] else { return }
            cell.configure(
                with: item,
                thumbnailURL: imageURLsByID[itemID],
                imagePipeline: imagePipeline
            )
        }

        dataSource = UICollectionViewDiffableDataSource<Section, String>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemID in
            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: itemID
            )
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

/// UIKit이 곧 필요할 것으로 예상한 셀의 이미지를 미리 준비합니다.
extension PopupPaginationUIKitViewController: UICollectionViewDataSourcePrefetching {
    /// 전달받은 IndexPath를 Item ID와 이미지 URL로 변환해 prefetch를 시작합니다.
    ///
    /// 같은 Item ID로 이미 시작한 작업이 있으면 중복 요청하지 않고,
    /// 반환된 token은 취소하거나 셀이 표시될 때 정리할 수 있도록 보관합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            guard let itemID = dataSource.itemIdentifier(for: indexPath),
                  prefetchTokens[itemID] == nil,
                  let url = imageURLsByID[itemID]
            else {
                continue
            }

            prefetchTokens[itemID] = imagePipeline.prefetchImage(at: url)
        }
    }

    /// UIKit이 더 이상 곧 표시되지 않을 것으로 판단한 이미지 prefetch를 취소합니다.
    ///
    /// IndexPath에 대응하는 Item ID의 token을 제거하고 이미지 파이프라인에
    /// 취소를 전달합니다. 표시 중인 셀이 같은 요청을 기다리고 있다면
    /// 이미지 파이프라인이 네트워크 작업을 유지합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            guard let itemID = dataSource.itemIdentifier(for: indexPath) else {
                continue
            }
            guard let token = prefetchTokens.removeValue(forKey: itemID) else {
                continue
            }
            imagePipeline.cancelPrefetch(token)
        }
    }
}

// MARK: - UICollectionViewDelegate

/// 셀 표시와 실제·예상 스크롤 위치를 이용해 이미지와 다음 페이지를 관리합니다.
extension PopupPaginationUIKitViewController: UICollectionViewDelegate {
    /// 셀이 표시되기 직전에 해당 Item의 prefetch token을 정리합니다.
    ///
    /// 셀 구성 단계의 표시용 이미지 요청은 이미 완료된 이미지를 소비하거나
    /// 진행 중인 prefetch에 합류합니다. 따라서 여기서 token을 취소해도
    /// 표시 중인 셀이 기다리는 네트워크 작업은 이미지 파이프라인이 유지합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let itemID = dataSource.itemIdentifier(for: indexPath),
              let token = prefetchTokens.removeValue(forKey: itemID)
        else {
            return
        }
        imagePipeline.cancelPrefetch(token)
    }

    /// 현재 contentOffset으로 다음 페이지를 검사합니다.
    ///
    /// 기본·예측 모드는 드래그와 감속 중에 검사합니다. Release Trigger 모드는
    /// PopPangListKit처럼 드래그·터치 중 검사를 건너뛰고,
    /// 감속 또는 프로그램 스크롤의 실제 위치만 보완해서 검사합니다.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch paginationTrigger {
        case .didScroll, .projectedTargetOffset:
            guard scrollView.isDragging || scrollView.isDecelerating else {
                return
            }

        case .releaseDrivenTargetOffset:
            guard !scrollView.isDragging, !scrollView.isTracking else {
                return
            }
        }

        loadNextPageIfNeeded(
            in: scrollView,
            contentOffset: scrollView.contentOffset
        )
    }

    /// 빠른 플릭의 예상 정지 위치로 다음 페이지를 미리 검사합니다.
    ///
    /// 예측·Release Trigger 모드에서 `targetContentOffset`을 사용하며,
    /// 실제 위치가 threshold에 도달하기 전에도 예상 위치가 기준을 넘으면
    /// 다음 페이지 요청을 시작합니다.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard paginationTrigger != .didScroll else { return }
        loadNextPageIfNeeded(
            in: scrollView,
            contentOffset: targetContentOffset.pointee
        )
    }

    /// 전달받은 위치가 목록 끝에서 화면 높이의 0.75배 이내인지 검사합니다.
    ///
    /// 조건을 만족하면 `canLoadNextPage`를 먼저 false로 변경해 두 scroll
    /// delegate의 중복 진입을 막고, `onReachedEnd`로 TCA action을 전달합니다.
    private func loadNextPageIfNeeded(
        in scrollView: UIScrollView,
        contentOffset: CGPoint
    ) {
        guard canLoadNextPage,
              scrollView.contentSize.height > scrollView.bounds.height
        else {
            return
        }

        let visibleBottom = contentOffset.y + scrollView.bounds.height
        let triggerOffset = scrollView.contentSize.height - scrollView.bounds.height * 0.75
        guard visibleBottom >= triggerOffset else { return }

        canLoadNextPage = false
        onReachedEnd()
    }
}

@MainActor
private final class PopupPaginationCollectionViewCell: UICollectionViewCell {
    private let cardView = PopupPaginationUIKitCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.reset()
    }

    func configure(
        with item: PopupPaginationItem,
        thumbnailURL: URL?,
        imagePipeline: PopupPaginationImagePipeline
    ) {
        cardView.configure(
            with: item,
            thumbnailURL: thumbnailURL,
            imagePipeline: imagePipeline
        )
    }
}

@MainActor
final class PopupPaginationUIKitCardView: UIView {
    private let thumbnailImageView = UIImageView()
    private let regionLabel = UILabel()
    private let favoriteImageView = UIImageView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let uuidLabel = UILabel()
    private var imagePipeline: PopupPaginationImagePipeline?
    private var imageLoadID: UUID?
    private var imageLoadGeneration = UUID()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
        reset()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        with item: PopupPaginationItem,
        thumbnailURL: URL?,
        imagePipeline: PopupPaginationImagePipeline
    ) {
        cancelImageLoad()
        self.imagePipeline = imagePipeline
        thumbnailImageView.image = UIImage(systemName: "photo")
        thumbnailImageView.tintColor = UIColor(Color.mainGray)
        regionLabel.text = item.region
        nameLabel.text = item.name
        dateLabel.text = "\(item.startDate) - \(item.endDate)"
        uuidLabel.text = item.popupUuid

        let heartName = item.isFavorited ? "heart.fill" : "heart"
        favoriteImageView.image = UIImage(systemName: heartName)
        favoriteImageView.tintColor = item.isFavorited
            ? UIColor(Color.mainOrange)
            : UIColor(Color.mainGray)

        guard let thumbnailURL else { return }
        let generation = UUID()
        imageLoadGeneration = generation
        imageLoadID = imagePipeline.loadImage(at: thumbnailURL) { [weak self] image in
            guard let self, imageLoadGeneration == generation else { return }
            thumbnailImageView.image = image ?? UIImage(systemName: "photo")
            imageLoadID = nil
        }
    }

    func reset() {
        cancelImageLoad()
        imagePipeline = nil
        thumbnailImageView.image = UIImage(systemName: "photo")
        thumbnailImageView.tintColor = UIColor(Color.mainGray)
        regionLabel.text = nil
        nameLabel.text = nil
        dateLabel.text = nil
        uuidLabel.text = nil
        favoriteImageView.image = nil
    }

    private func cancelImageLoad() {
        imageLoadGeneration = UUID()
        guard let imageLoadID else { return }
        imagePipeline?.cancelImageLoad(imageLoadID)
        self.imageLoadID = nil
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        systemLayoutSizeFitting(
            CGSize(
                width: size.width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}

private extension PopupPaginationUIKitCardView {
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

        regionLabel.font = .scdream(.bold, size: 11)
        regionLabel.textColor = UIColor(Color.mainOrange)

        favoriteImageView.contentMode = .scaleAspectFit

        nameLabel.font = .scdream(.bold, size: 15)
        nameLabel.textColor = UIColor(Color.mainBlack)
        nameLabel.numberOfLines = 2

        dateLabel.font = .scdream(.regular, size: 11)
        dateLabel.textColor = UIColor(Color.mainGray)
        dateLabel.numberOfLines = 1

        uuidLabel.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
        uuidLabel.textColor = UIColor(Color.mainGray.opacity(0.7))
        uuidLabel.numberOfLines = 1
    }

    func configureLayout() {
        let topSpacer = UIView()
        let topRow = UIStackView(arrangedSubviews: [
            regionLabel,
            topSpacer,
            favoriteImageView,
        ])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let flexibleSpacer = UIView()
        flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)

        let detailStack = UIStackView(arrangedSubviews: [
            topRow,
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

        addSubview(contentStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 102),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 126),
            favoriteImageView.widthAnchor.constraint(equalToConstant: 18),
            favoriteImageView.heightAnchor.constraint(equalToConstant: 18),
        ])
    }
}
