import Core
import Domain
import DSKit
import Kingfisher
import ListKit
import SwiftUI
import UIKit

public struct HomeFeatureView: View {
    @Environment(HomeFeatureCoordinator.self) private var coordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var compound: HomeFeatureCompound
    @State private var hasSeenPopup = false
    @State private var currentScrollOffset: CGFloat = 0
    @State private var listProxy = LKListProxy()
    @State private var lastHandledPopupId: String?
    @State private var sheetRoute: HomeSheetRoute?

    private let deepLinkStorage: DeepLinkStorage

    public init(
        userUuid: String = "demo-user",
        nickname: String = "닉네임",
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore())
    ) {
        let compound = HomeFeatureCompound(userUuid: userUuid, nickname: nickname)
        _compound = State(wrappedValue: compound)
        self.deepLinkStorage = deepLinkStorage
        Task { @MainActor in
            compound.preload()
        }
    }

    public var body: some View {
        ZStack {
            Color.subWhite
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                LKList {
                    LKSection(id: "best") {
                        for popup in compound.state.bestPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitBestPopupCell"
                            ) {
                                ListKitBestPopupCell(popup: popup)
                                    .frame(width: 194, height: 271)
                            }
                            .onSelect { _ in
                                coordinator.push(.popupDetail(userUuid: compound.state.userUuid, popup: popup))
                            }
                        }
                    } header: {
                        bestHeader
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.custom(Self.horizontalSectionLayout(width: 194, height: 271, spacing: 15, bottomInset: 50)))
                    .scrollAxis(.horizontal)
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "coming") {
                        for popup in compound.state.comingPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitComingPopupCell"
                            ) {
                                ListKitComingPopupCell(popup: popup)
                                    .frame(width: 283, height: 138)
                            }
                            .onSelect { _ in
                                coordinator.push(.popupDetail(userUuid: compound.state.userUuid, popup: popup))
                            }
                        }
                    } header: {
                        comingHeader
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.custom(Self.horizontalSectionLayout(width: 283, height: 138, spacing: 15, bottomInset: 65)))
                    .scrollAxis(.horizontal)
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "grid") {
                        for popup in compound.state.gridPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitGridPopupCell"
                            ) {
                                ListKitGridPopupCell(
                                    popup: popup,
                                    isLiked: isLiked(popup: popup),
                                    cellWidth: Self.gridCellWidth,
                                    toggleLike: { compound.send(.toggleLike(popup)) }
                                )
                            }
                            .equatableToken("\(popup.popupUuid)-\(isLiked(popup: popup))")
                            .onSelect { _ in
                                coordinator.push(.popupDetail(userUuid: compound.state.userUuid, popup: popup))
                            }
                        }
                    } header: {
                        filterHeader
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.custom(Self.gridSectionLayout(columns: 2, itemHeight: 302, columnSpacing: 15, rowSpacing: 20)))
                    .pinnedHeader(background: Color.subWhite)
                }
                .listKitStyle(.plain)
                .updateEngine(.reloadData)
                .scrollIndicators(.hidden)
                .contentInsets(LKEdgeInsets(top: 0, left: 0, bottom: 50, right: 0))
                .listProxy(listProxy)
                .onScroll { context in
                    currentScrollOffset = context.contentOffset.y
                }
                .overlay(topAnchorButton, alignment: Alignment.bottomTrailing)
            }
        }
        .withoutAnimation()
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .regionSheet:
                RegionButtonSheet(
                    regions: compound.state.regions,
                    selectedRegion: selectedRegionBinding,
                    selectedDistrict: selectedDistrictBinding,
                    regionTitle: { $0.region },
                    districts: { $0.districtList }
                )
                .presentationDetents([.medium])
            case .sortSheet:
                SortButtonSheet(selectedOption: selectedOptionBinding)
                    .presentationDetents([.height(270)])
            }
        }
        .onAppear {
            compound.preload()

            if !hasSeenPopup {
                hasSeenPopup = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    handleDeeplinkIfNeeded()
                }
            }
        }
    }
}

private extension HomeFeatureView {
    static func horizontalSectionLayout(
        width: CGFloat,
        height: CGFloat,
        spacing: CGFloat,
        bottomInset: CGFloat = 0
    ) -> LKCustomSectionLayoutProvider {
        { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(width),
                heightDimension: .absolute(height)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: itemSize,
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: .contentPadding,
                bottom: bottomInset,
                trailing: .contentPadding
            )
            section.boundarySupplementaryItems = [headerItem()]
            return section
        }
    }

    static func gridSectionLayout(
        columns: Int,
        itemHeight: CGFloat,
        columnSpacing: CGFloat,
        rowSpacing: CGFloat
    ) -> LKCustomSectionLayoutProvider {
        { _, environment in
            let safeColumns = max(columns, 1)
            let groupWidth = max(
                environment.container.effectiveContentSize.width - CGFloat.contentPadding * 2,
                0
            )
            let totalColumnSpacing = columnSpacing * CGFloat(safeColumns - 1)
            let itemWidth = max((groupWidth - totalColumnSpacing) / CGFloat(safeColumns), 0)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(groupWidth),
                heightDimension: .absolute(itemHeight)
            )
            let group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
                (0..<safeColumns).map { column in
                    let x = CGFloat(column) * (itemWidth + columnSpacing)
                    return NSCollectionLayoutGroupCustomItem(
                        frame: CGRect(x: x, y: 0, width: itemWidth, height: itemHeight)
                    )
                }
            }

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = rowSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: .contentPadding,
                bottom: 0,
                trailing: .contentPadding
            )
            section.boundarySupplementaryItems = [headerItem()]
            return section
        }
    }

    static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(44)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    static var gridCellWidth: CGFloat {
        (UIScreen.main.bounds.width - CGFloat.contentPadding * 2 - 15) / 2
    }
}

private extension HomeFeatureView {
    var navigationBar: some View {
        CustomNavigationBar {
            Text("POP PANG")
                .ppStyleFont(.scdream(.black, size: 20))
                .foregroundStyle(Color.mainOrange)

            Spacer()

            IconButton(image: "SearchDark", imageSize: 25) {
                coordinator.presentFullScreen(.search(uuid: compound.state.userUuid))
            }
            .accessibilityIdentifier("home_search_button")

            IconButton {
                coordinator.push(.alert(userUuid: compound.state.userUuid))
            }
        }
        .padding(.bottom, 15)
    }

    var bestHeader: some View {
        HStack(spacing: 0) {
            Text(compound.state.nickname)
                .foregroundStyle(Color.mainOrange)
                .font(.scdream(.bold, size: 15))

            Text("님을 위한 팝업")
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Spacer()
        }
    }

    var comingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("COMING SOON")
                    .font(.scdream(.medium, size: 11))
                    .foregroundStyle(Color.mainOrange)

                Text("오픈 예정 팝업")
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.mainBlack)
            }

            Spacer()

            Button {
                coordinator.push(.comingPopupDetail(
                    userUuid: compound.state.userUuid,
                    popups: compound.state.comingPopups
                ))
            } label: {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
            .accessibilityIdentifier("home_comming_button")
        }
    }

    var filterHeader: some View {
        HStack {
            Text(compound.state.selectedRegion?.region ?? "전체")
                .foregroundStyle(Color.mainBlack)
                .ppStyleFont(.scdream(.medium, size: 17))

            if let selectedDistrict = compound.state.selectedDistrict,
               selectedDistrict != "전체" {
                Text(selectedDistrict)
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.medium, size: 17))
            }

            Spacer()

            RegionButton(text: "지역") {
                sheetRoute = .regionSheet
            }
            .padding(.leading, -10)
            .accessibilityIdentifier("home_region_dropdown")

            SortButton(selectedOption: selectedOptionBinding) {
                sheetRoute = .sortSheet
            }
            .accessibilityIdentifier("home_sort_dropdown")
        }
    }

    var topAnchorButton: some View {
        Button {
            // listProxy.scrollToTop(animated: true) 하면 최상단으로 이동
            listProxy.scrollToSection(id: "grid", position: .top, animated: true)
        } label: {
            DSKitResource.image("TopAnchor")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.mainBlack)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(Color.subWhite)
                        .applyShadow(
                            color: Color.subBlack,
                            alpha: 0.05,
                            x: 0,
                            y: 4,
                            blur: 4
                        )
                }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .opacity(currentScrollOffset > 650 ? 1 : 0)
    }
}

private struct ListKitBestPopupCell: View {
    let popup: Popup

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KFImage(URL(string: popup.imageUrlList.first ?? ""))
                .downSampled(.bestPopupCell)
                .scaledToFill()
                .frame(width: 194, height: 271)
                .clipped()

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.mainBlack.opacity(0.0), location: 0.00),
                    .init(color: Color.mainBlack.opacity(0.50), location: 0.52),
                    .init(color: Color.mainBlack.opacity(1.00), location: 0.83),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .clipped()

            VStack(alignment: .leading) {
                Text(popup.name)
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.bestPostTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 2) {
                    DSKitResource.image("Address")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.bestPostAddress)
                        .frame(width: 15, height: 15)

                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.bestPostAddress)
                }
            }
            .padding(11)
        }
        .contentShape(Rectangle())
    }
}

private struct ListKitComingPopupCell: View {
    let popup: Popup

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.subWhite)
                .frame(width: 283, height: 138)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.mainGray3, lineWidth: 0.05)
                }
                .applyShadow(color: .subWhite2, alpha: 0.2, x: 0, y: 0, blur: 13)

            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .downSampled(.comingPopupCell)
                    .scaledToFill()
                    .frame(width: 94.4, height: 118)
                    .cornerRadius(5)
                    .clipped()
                    .padding(10)

                VStack(alignment: .leading, spacing: 5) {
                    Text(dDay(date: popup.startDate))
                        .font(.scdream(.bold, size: 11))
                        .foregroundStyle(Color.mainOrange)

                    Text(popup.name)
                        .font(.scdream(.medium, size: 13))
                        .foregroundStyle(Color.mainBlack)

                    Spacer()

                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 11))
                        .foregroundStyle(Color.mainGray)
                }
                .padding(.vertical, 15)

                Spacer()
            }
            .frame(width: 283, height: 138)
        }
        .contentShape(Rectangle())
    }

    private func dDay(date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)

        if let diff = calendar.dateComponents([.day], from: today, to: target).day {
            if diff > 0 {
                return "오픈 D-\(diff)"
            } else {
                return "오늘 오픈"
            }
        }
        return ""
    }
}

private struct ListKitGridPopupCell: View {
    let popup: Popup
    let isLiked: Bool
    let cellWidth: CGFloat
    let toggleLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.subWhite)
                            .frame(width: cellWidth, height: 217)
                    }
                    .downSampled(.gridPopupCell)
                    .scaledToFill()
                    .frame(width: cellWidth, height: 217)
                    .clipped()

                Button {
                    toggleLike()
                } label: {
                    DSKitResource.image(isLiked ? "favorite_fill" : "favorite")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundStyle(isLiked ? Color.mainOrange : Color.subWhite)
                }
                .padding(10)
                .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
            }
            .frame(width: cellWidth, height: 217)

            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)

            Text(popup.name)
                .font(.scdream(.medium, size: 14))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 5)

            Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                .foregroundStyle(Color.mainGray)
                .padding(.top, 5)
        }
        .frame(width: cellWidth, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private extension HomeFeatureView {
    var selectedRegionBinding: Binding<RegionList?> {
        Binding(
            get: { compound.state.selectedRegion },
            set: { region in
                guard let region else { return }
                compound.send(.regionSelected(region))
            }
        )
    }

    var selectedDistrictBinding: Binding<String?> {
        Binding(
            get: { compound.state.selectedDistrict },
            set: { district in
                guard let district else { return }
                compound.send(.districtSelected(district))
                sheetRoute = nil
            }
        )
    }

    var selectedOptionBinding: Binding<SortButton.SortOption> {
        Binding(
            get: { compound.state.selectedOption },
            set: { option in
                compound.send(.sortOptionSelected(option))
                sheetRoute = nil
            }
        )
    }

    func isLiked(popup: Popup) -> Bool {
        compound.state.gridPopups.first { $0.popupUuid == popup.popupUuid }?.isFavorited ?? popup.isFavorited
    }
}

private extension HomeFeatureView {
    func handleDeeplinkIfNeeded() {
        Task {
            guard let popupId = deepLinkStorage.loadPopupID(),
                  lastHandledPopupId != popupId
            else {
                return
            }

            while compound.state.bestPopups.isEmpty &&
                compound.state.comingPopups.isEmpty &&
                compound.state.gridPopups.isEmpty {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            await MainActor.run {
                moveToPopupDetailIfExists(popupId: popupId)
                deepLinkStorage.removePopupID()
                lastHandledPopupId = popupId
            }
        }
    }

    func moveToPopupDetailIfExists(popupId: String) {
        let allPopups = compound.state.bestPopups
            + compound.state.comingPopups
            + compound.state.gridPopups

        if let targetPopup = allPopups.first(where: { $0.popupUuid == popupId }) {
            coordinator.push(.popupDetail(userUuid: compound.state.userUuid, popup: targetPopup))
        }
    }
}

public struct ComingPopupDetailFeatureView: View {
    @State private var compound: ComingPopupDetailCompound
    private let onSelectPopup: (String, Popup) -> Void

    public init(
        userUuid: String,
        popups: [Popup],
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
    ) {
        _compound = State(
            wrappedValue: ComingPopupDetailCompound(
                userUuid: userUuid,
                popups: popups
            )
        )
        self.onSelectPopup = onSelectPopup
    }

    public var body: some View {
        LKList {
            LKSection(id: "coming-popup-detail") {
                for popup in compound.state.popups {
                    LKRow(
                        popup,
                        id: \.popupUuid,
                        reuseIdentifier: "HomeFeature.ListKitGridPopupCell"
                    ) {
                        ListKitGridPopupCell(
                            popup: popup,
                            isLiked: popup.isFavorited,
                            cellWidth: HomeFeatureView.gridCellWidth,
                            toggleLike: {
                                compound.send(.toggleLike(popup))
                            }
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("home_comming_cell")
                    }
                    .equatableToken("\(popup.popupUuid)-\(popup.isFavorited)")
                    .onSelect { _ in
                        onSelectPopup(compound.state.userUuid, popup)
                    }
                }
            }
            .sectionLayout(.custom(HomeFeatureView.gridSectionLayout(columns: 2, itemHeight: 302, columnSpacing: 15, rowSpacing: 20)))
            .pinnedHeader(background: Color.subWhite)
        }
        .listKitStyle(.plain)
        .updateEngine(.reloadData)
        .scrollIndicators(.hidden)
        .contentInsets(LKEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
}
