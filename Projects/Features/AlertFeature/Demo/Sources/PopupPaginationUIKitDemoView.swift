import ComposableArchitecture
import DSKit
import SwiftUI
import UIKit

struct PopupPaginationUIKitDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>
    @State private var imagePipeline = PopupPaginationImagePipeline()

    var body: some View {
        PopupPaginationDemoScaffold(
            implementationTitle: "UIKIT",
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
                    imagePipeline: imagePipeline
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
    let onReachedEnd: () -> Void

    func makeUIViewController(context: Context) -> PopupPaginationUIKitViewController {
        PopupPaginationUIKitViewController(
            imagePipeline: imagePipeline,
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
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, String>!
    private var itemsByID: [String: PopupPaginationItem] = [:]
    private var prefetchTokens: [String: UUID] = [:]
    private var canLoadNextPage = false

    init(
        imagePipeline: PopupPaginationImagePipeline,
        onReachedEnd: @escaping () -> Void
    ) {
        self.imagePipeline = imagePipeline
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

    func configureDataSource() {
        let registration = UICollectionView.CellRegistration<
            PopupPaginationCollectionViewCell,
            String
        > { [weak self] cell, _, itemID in
            guard let self, let item = itemsByID[itemID] else { return }
            cell.configure(
                with: item,
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

extension PopupPaginationUIKitViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        for indexPath in indexPaths {
            guard let itemID = dataSource.itemIdentifier(for: indexPath),
                  prefetchTokens[itemID] == nil,
                  let url = itemsByID[itemID]?.thumbnailURL
            else {
                continue
            }

            prefetchTokens[itemID] = imagePipeline.prefetchImage(at: url)
        }
    }

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

extension PopupPaginationUIKitViewController: UICollectionViewDelegate {
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard canLoadNextPage,
              scrollView.isDragging || scrollView.isDecelerating,
              scrollView.contentSize.height > scrollView.bounds.height
        else {
            return
        }

        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
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
        imagePipeline: PopupPaginationImagePipeline
    ) {
        cardView.configure(
            with: item,
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

        guard let thumbnailURL = item.thumbnailURL else { return }
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
