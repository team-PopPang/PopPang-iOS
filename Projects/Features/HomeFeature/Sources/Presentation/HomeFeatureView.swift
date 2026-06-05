import Compound
import Core
import Domain
import DSKit
import Kingfisher
import ListKit
import SwiftUI
import UIKit

public struct HomeFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var compound: HomeFeatureCompound
    @State private var currentScrollOffset: CGFloat = 0
    @State private var listProxy = LKListProxy()
    @State private var lastHandledPopupId: String?
    @State private var sheetRoute: HomeSheetRoute?
    @StateObject private var nativeAdViewModel = HomeNativeAdViewModel()

    private let deepLinkStorage: DeepLinkStorage
    private let onSelectPopup: (String, Popup) -> Void
    private let onShowAlert: (String) -> Void
    private let onSearch: (String) -> Void
    private let onShowComingPopups: (String, [Popup]) -> Void
    private let onReport: ((String) -> Void)?
    private let onManagePopupRequests: (() -> Void)?
    private let isAdmin: Bool

    public init(
        userUuid: String = "demo-user",
        nickname: String = "닉네임",
        isAdmin: Bool = false,
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore()),
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onShowAlert: @escaping (String) -> Void = { _ in },
        onSearch: @escaping (String) -> Void = { _ in },
        onShowComingPopups: @escaping (String, [Popup]) -> Void = { _, _ in },
        onReport: ((String) -> Void)? = nil,
        onManagePopupRequests: (() -> Void)? = nil
    ) {
        let compound = HomeFeatureCompound(userUuid: userUuid, nickname: nickname)
        _compound = State(wrappedValue: compound)
        self.isAdmin = isAdmin
        self.deepLinkStorage = deepLinkStorage
        self.onSelectPopup = onSelectPopup
        self.onShowAlert = onShowAlert
        self.onSearch = onSearch
        self.onShowComingPopups = onShowComingPopups
        self.onReport = onReport
        self.onManagePopupRequests = onManagePopupRequests
    }

    public var body: some View {
        ZStack {
            Color.subWhite
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HomeNavigationBar(
                    userUuid: compound.state.userUuid,
                    showsPopupRequestManagement: isAdmin && onManagePopupRequests != nil,
                    onSearch: { userUuid in
                        onSearch(userUuid)
                    },
                    onAlert: { userUuid in
                        onShowAlert(userUuid)
                    },
                    onReport: {
                        if let onReport {
                            onReport(compound.state.userUuid)
                        }
                    },
                    onManagePopupRequests: {
                        onManagePopupRequests?()
                    }
                )

                LKList {
                    LKSection(id: "best") {
                        for popup in compound.state.bestPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitBestPopupCell"
                            ) {
                                ListKitBestPopupCell(popup: popup)
//                                    .frame(width: 194, height: 271)
                            }
                            .onSelect { _ in
                                onSelectPopup(compound.state.userUuid, popup)
                            }
                        }
                    } header: {
                        HomeBestHeader(nickname: compound.state.nickname)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.horizontal(width: 194, height: 271))
                    .scrollAxis(.horizontal)
                    .orthogonalScrollingBehavior(.continuousGroupLeadingBoundary)
                    .itemSpacing(15)
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 50,
                        right: .contentPadding
                    ))
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "coming") {
                        for popup in compound.state.comingPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitComingPopupCell"
                            ) {
                                ListKitComingPopupCell(popup: popup)
//                                    .frame(width: 283, height: 138)
                            }
                            .onSelect { _ in
                                onSelectPopup(compound.state.userUuid, popup)
                            }
                        }
                    } header: {
                        HomeComingHeader(
                            userUuid: compound.state.userUuid,
                            popups: compound.state.comingPopups,
                            onTap: { _, _ in
                                onShowComingPopups(
                                    compound.state.userUuid,
                                    compound.state.comingPopups
                                )
                            }
                        )
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.horizontal(width: 283, height: 138))
                    .scrollAxis(.horizontal)
                    .orthogonalScrollingBehavior(.groupPaging)
                    .itemSpacing(15)
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 65,
                        right: .contentPadding
                    ))
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "grid") {
                        for item in HomeNativeAdGridItemBuilder.make(
                            popups: compound.state.gridPopups,
                            includesNativeAd: nativeAdViewModel.nativeAd != nil
                        ) {
                            switch item {
                            case let .popup(popup):
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
                                    onSelectPopup(compound.state.userUuid, popup)
                                }

                            case .nativeAd:
                                LKRow(
                                    id: item.id,
                                    reuseIdentifier: "HomeFeature.HomeNativeAdGridCell"
                                ) {
                                    HomeNativeAdGridCellView(viewModel: nativeAdViewModel)
//                                        .frame(width: Self.gridCellWidth, height: Self.gridCellHeight)
                                }
                                .equatableToken(item.id)
                            }
                        }
                    } header: {
                        HomeFilterHeader(
                            selectedRegion: compound.state.selectedRegion,
                            selectedDistrict: compound.state.selectedDistrict,
                            selectedOption: selectedOptionBinding,
                            onRegionTap: {
                                sheetRoute = .regionSheet
                            },
                            onSortTap: {
                                sheetRoute = .sortSheet
                            }
                        )
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sectionLayout(.grid(columns: 2, itemHeight: Self.gridCellHeight, columnSpacing: 15, rowSpacing: 20))
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 0,
                        right: .contentPadding
                    ))
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
                .overlay(alignment: Alignment.bottomTrailing) {
                    HomeTopAnchorButton(isVisible: currentScrollOffset > 650) {
                        listProxy.scrollToSection(id: "grid", position: .top, animated: true)
                    }
                }
            }
        }
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
            compound.send(.onAppear)
            nativeAdViewModel.loadAdIfNeeded()
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
    static let gridCellHeight: CGFloat = 302

    static var gridCellWidth: CGFloat {
        (UIScreen.main.bounds.width - CGFloat.contentPadding * 2 - 15) / 2
    }
}

private struct HomeNavigationBar: View {
    let userUuid: String
    let showsPopupRequestManagement: Bool
    let onSearch: (String) -> Void
    let onAlert: (String) -> Void
    let onReport: () -> Void
    let onManagePopupRequests: () -> Void

    var body: some View {
        CustomNavigationBar {
            Text("POP PANG")
                .ppStyleFont(.scdream(.black, size: 20))
                .foregroundStyle(Color.mainOrange)

            Spacer()

            IconButton(image: "SearchDark", imageSize: 25) {
                onSearch(userUuid)
            }
            .accessibilityIdentifier("home_search_button")

            IconButton {
                onAlert(userUuid)
            }

            HomeReportButton {
                onReport()
            }
            .accessibilityIdentifier("home_popup_report_button")

            if showsPopupRequestManagement {
                HomePopupRequestManagementButton {
                    onManagePopupRequests()
                }
                .accessibilityIdentifier("home_popup_request_management_button")
            }
        }
        .padding(.bottom, 15)
    }
}

private struct HomeReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .offset(y: -1.5)
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HomePopupRequestManagementButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "tray.full")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HomeBestHeader: View {
    let nickname: String

    var body: some View {
        HStack(spacing: 0) {
            Text(nickname)
                .foregroundStyle(Color.mainOrange)
                .font(.scdream(.bold, size: 15))

            Text("님을 위한 팝업")
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Spacer()
        }
    }
}

private struct HomeComingHeader: View {
    let userUuid: String
    let popups: [Popup]
    let onTap: (String, [Popup]) -> Void

    var body: some View {
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
                onTap(userUuid, popups)
            } label: {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
            .accessibilityIdentifier("home_comming_button")
        }
    }
}

private struct HomeFilterHeader: View {
    let selectedRegion: RegionList?
    let selectedDistrict: String?
    @Binding var selectedOption: SortButton.SortOption
    let onRegionTap: () -> Void
    let onSortTap: () -> Void

    var body: some View {
        HStack {
            Text(selectedRegion?.region ?? "전체")
                .foregroundStyle(Color.mainBlack)
                .ppStyleFont(.scdream(.medium, size: 17))

            if let selectedDistrict, selectedDistrict != "전체" {
                Text(selectedDistrict)
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.medium, size: 17))
            }

            Spacer()

            RegionButton(text: "지역", action: onRegionTap)
                .padding(.leading, -10)
                .accessibilityIdentifier("home_region_dropdown")

            SortButton(selectedOption: $selectedOption, action: onSortTap)
                .accessibilityIdentifier("home_sort_dropdown")
        }
    }
}

private struct HomeTopAnchorButton: View {
    let isVisible: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
        .opacity(isVisible ? 1 : 0)
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
            onSelectPopup(compound.state.userUuid, targetPopup)
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
            .sectionLayout(.grid(columns: 2, itemHeight: HomeFeatureView.gridCellHeight, columnSpacing: 15, rowSpacing: 20))
            .sectionContentInsets(LKEdgeInsets(
                top: 0,
                left: .contentPadding,
                bottom: 0,
                right: .contentPadding
            ))
            .pinnedHeader(background: Color.subWhite)
        }
        .listKitStyle(.plain)
        .updateEngine(.reloadData)
        .scrollIndicators(.hidden)
        .contentInsets(LKEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        .onAppear {
            compound.send(.onAppear)
        }
    }
}

#if DEBUG
#Preview("HomeFeatureView") {
    HomeFeaturePreviewContainer()
}

private struct HomeFeaturePreviewContainer: View {
    @State private var coordinator = HomeFeatureCoordinator()

    init() {
        DIContainer.shared.register(
            HomeFeaturePreviewPopupUsecase(),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some View {
        HomeFeatureView(
            userUuid: "preview-user",
            nickname: "팝팡"
        )
        .environment(coordinator)
    }
}

private final class HomeFeaturePreviewPopupUsecase: PopupUsecaseProtocol {
    private let popups: [Popup] = [
        .preview(
            popupUuid: "preview-1",
            name: "성수 라이프스타일 팝업",
            roadAddress: "서울 성동구 성수동",
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 12),
            favoriteCount: 124,
            viewCount: 851,
            isFavorited: true,
            recommendList: ["생활용품", "친환경"]
        ),
        .preview(
            popupUuid: "preview-2",
            name: "홍대 디저트 마켓",
            roadAddress: "서울 마포구 서교동",
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 5),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 15),
            favoriteCount: 78,
            viewCount: 430,
            recommendList: ["디저트", "카페"]
        ),
        .preview(
            popupUuid: "preview-3",
            name: "더현대 패션 쇼룸",
            roadAddress: "서울 영등포구 여의도동",
            startDate: Date().addingTimeInterval(-60 * 60 * 24),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 8),
            favoriteCount: 210,
            viewCount: 1_924,
            recommendList: ["패션", "뷰티"]
        ),
        .preview(
            popupUuid: "preview-4",
            name: "잠실 캐릭터 굿즈 페어",
            roadAddress: "서울 송파구 잠실동",
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 9),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 20),
            favoriteCount: 56,
            viewCount: 619,
            isFavorited: true,
            recommendList: ["애니메이션", "게임"]
        ),
    ]

    func getPopupList() async throws -> [Popup] {
        popups
    }

    func getUpcomingPopupList() async throws -> [Popup] {
        popups
    }

    func getInProgressPopupList() async throws -> [Popup] {
        popups
    }

    func getFavoriteList(userUuid: String) async throws -> [Popup] {
        popups.filter(\.isFavorited)
    }

    func searchPopupList(searchText: String) async throws -> [Popup] {
        popups
    }

    func getRandomPopupList() async throws -> [Popup] {
        popups
    }

    func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        popups
    }

    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        popups
    }

    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        popups
    }

    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        popups.filter { $0.popupUuid != popupUuid }
    }

    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {}

    func increaseViewCount(popupUuid: String) async throws {}

    func addFavorite(userUuid: String, popupUuid: String) async throws {}

    func removeFavorite(userUuid: String, popupUuid: String) async throws {}

    func getRegionList() async throws -> [RegionList] {
        [
            RegionList(region: "전체", districtList: ["전체"]),
            RegionList(region: "서울", districtList: ["전체", "성동구", "마포구", "영등포구", "송파구"]),
            RegionList(region: "부산", districtList: ["전체", "해운대구", "수영구"]),
        ]
    }

    func getPopularRecommendList() async throws -> [Recommend] {
        [
            Recommend(id: 1, recommendName: "패션"),
            Recommend(id: 2, recommendName: "디저트"),
            Recommend(id: 3, recommendName: "뷰티"),
        ]
    }

    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        popups
    }
}

private extension Popup {
    static func preview(
        popupUuid: String,
        name: String,
        roadAddress: String,
        startDate: Date,
        endDate: Date,
        favoriteCount: Int,
        viewCount: Int,
        isFavorited: Bool = false,
        recommendList: [String]
    ) -> Popup {
        Popup(
            popupUuid: popupUuid,
            name: name,
            startDate: startDate,
            endDate: endDate,
            openTime: "10:00",
            closeTime: "20:00",
            address: roadAddress,
            roadAddress: roadAddress,
            region: "서울",
            latitude: 37.544,
            longitude: 127.055,
            instaPostId: nil,
            instaPostUrl: nil,
            captionSummary: "프리뷰용 팝업 소개 문구입니다.",
            imageUrlList: [
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
            ],
            mediaType: .image,
            favoriteCount: favoriteCount,
            viewCount: viewCount,
            isFavorited: isFavorited,
            recommendList: recommendList
        )
    }
}
#endif
