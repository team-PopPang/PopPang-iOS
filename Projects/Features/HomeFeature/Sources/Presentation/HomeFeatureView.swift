import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI

public struct HomeFeatureView: View {
    @Environment(HomeFeatureCoordinator.self) private var coordinator
    @State private var viewState = HomeViewState()
    @State private var hasSeenPopup = false
    @State private var startScrollOffset: CGFloat = 0
    @State private var currentScrollOffset: CGFloat = 0

    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CustomNavigationBar {
                    Text("POP PANG")
                        .ppStyleFont(.scdream(.black, size: 20))
                        .foregroundStyle(Color.mainOrange)

                    Spacer()

                    IconButton(image: "SearchDark", imageSize: 25) {
                        coordinator.push(.search)
                    }
                    .accessibilityIdentifier("home_search_button")

                    IconButton {
                        coordinator.push(.alert)
                    }
                }
                .padding(.bottom, 15)

                ScrollViewReader { proxyHeader in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Text(viewState.nickname)
                                        .foregroundStyle(Color.mainOrange)
                                        .font(.scdream(.bold, size: 15))

                                    Text("님을 위한 팝업")
                                        .font(.scdream(.bold, size: 15))
                                        .foregroundStyle(Color.mainBlack)
                                }

                                BestPopupScrollView(
                                    popups: viewState.bestPopups,
                                    onSelect: { _ in coordinator.push(.popupDetail) }
                                )
                                .padding(.top, 15)
                            }

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
                                    coordinator.push(.comingSoon)
                                } label: {
                                    Image("navigationButton")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                }
                                .padding(.trailing, .contentPadding)
                                .accessibilityIdentifier("home_comming_button")
                            }
                            .padding(.top, 50)

                            ComingPopupScrollView(
                                popups: viewState.comingPopups,
                                onSelect: { _ in coordinator.push(.popupDetail) }
                            )

                            HStack {
                                Text(viewState.selectedRegion?.region ?? "전체")
                                    .foregroundStyle(Color.mainBlack)
                                    .ppStyleFont(.scdream(.medium, size: 17))

                                if let selectedDistrict = viewState.selectedDistrict,
                                   selectedDistrict != "전체" {
                                    Text(selectedDistrict)
                                        .foregroundStyle(Color.mainBlack)
                                        .ppStyleFont(.scdream(.medium, size: 17))
                                }

                                Spacer()

                                RegionButton(text: "지역") {
                                    viewState.showRegionSheet = true
                                }
                                .padding(.leading, -10)
                                .accessibilityIdentifier("home_region_dropdown")

                                SortButton(selectedOption: $viewState.selectedOption) {
                                    viewState.showSortSheet = true
                                }
                                .accessibilityIdentifier("home_sort_dropdown")
                            }
                            .padding(.top, 50)
                            .padding(.trailing, .contentPadding)
                            .id("Scroll_To_Top")

                            GridPopupScrollView(
                                popups: viewState.gridPopups,
                                isLiked: { popup in viewState.isLiked(popup: popup) },
                                toggleLike: { popup in viewState.toggleLike(popup: popup) },
                                onSelect: { _ in coordinator.push(.popupDetail) }
                            )
                            .padding(.top, 15)
                            .padding(.trailing, .contentPadding)
                        }
                        .padding(.bottom, 50)
                        .overlay(
                            GeometryReader { proxy -> Color in
                                DispatchQueue.main.async {
                                    if startScrollOffset == 0 {
                                        startScrollOffset = proxy.frame(in: .named("scroll")).minY
                                    }
                                    let offset = proxy.frame(in: .named("scroll")).minY
                                    currentScrollOffset = offset - startScrollOffset
                                }
                                return Color.clear
                            }
                            .frame(width: 0, height: 0),
                            alignment: .top
                        )
                    }
                    .padding(.leading, .contentPadding)
                    .coordinateSpace(name: "scroll")
                    .overlay(
                        Button {
                            withAnimation(.default) {
                                proxyHeader.scrollTo("Scroll_To_Top", anchor: .top)
                            }
                        } label: {
                            Image("TopAnchor")
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
                        .opacity(currentScrollOffset < -650 ? 1 : 0),
                        alignment: .bottomTrailing
                    )
                }
            }
        }
        .sheet(isPresented: $viewState.showRegionSheet) {
            HomeRegionSheet(
                regions: viewState.regions,
                selectedRegion: $viewState.selectedRegion,
                selectedDistrict: $viewState.selectedDistrict
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewState.showSortSheet) {
            SortButtonSheet(selectedOption: $viewState.selectedOption)
                .presentationDetents([.height(270)])
        }
        .onAppear {
            if !hasSeenPopup {
                hasSeenPopup = true
            }
        }
        .withoutAnimation()
    }
}

private struct BestPopupScrollView: View {
    let popups: [Popup]
    let onSelect: (Popup) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(popups, id: \.self) { popup in
                    BestPopupCell(popup: popup)
                        .onTapGesture {
                            onSelect(popup)
                        }
                }
            }
            .padding(.trailing, .contentPadding)
        }
    }
}

private struct ComingPopupScrollView: View {
    let popups: [Popup]
    let onSelect: (Popup) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(popups, id: \.self) { popup in
                    ComingPopupCell(popup: popup)
                        .onTapGesture {
                            onSelect(popup)
                        }
                }
            }
            .padding(.vertical, 15)
            .padding(.trailing, .contentPadding)
        }
    }
}

private struct GridPopupScrollView: View {
    let popups: [Popup]
    let isLiked: (Popup) -> Bool
    let toggleLike: (Popup) -> Void
    let onSelect: (Popup) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(popups) { popup in
                VStack(alignment: .leading) {
                    GridPopupCell(
                        popup: popup,
                        isLiked: isLiked(popup),
                        toggleLike: { toggleLike(popup) }
                    )
                    .onTapGesture {
                        onSelect(popup)
                    }
                    .padding(.bottom, 0)
                }
            }
        }
    }
}

private struct BestPopupCell: View {
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
                    Image("Address")
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
        .frame(width: 194, height: 271)
        .contentShape(Rectangle())
    }
}

private struct ComingPopupCell: View {
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

private struct GridPopupCell: View {
    let popup: Popup
    let isLiked: Bool
    let toggleLike: () -> Void

    private let cellWidth: CGFloat = (UIScreen.main.bounds.width - 15 * 3) / 2

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

                BookmarkButton(
                    isLiked: isLiked,
                    info: .stroke,
                    action: toggleLike
                )
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
        .contentShape(Rectangle())
    }
}

private struct BookmarkButton: View {
    enum Info {
        case fill
        case stroke
    }

    var isLiked: Bool
    var info: Info
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            switch info {
            case .fill:
                Image(isLiked ? "favorite_fill" : "favorite")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            case .stroke:
                Image(isLiked ? "favorite_fill" : "favorite")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(isLiked ? Color.mainOrange : Color.subWhite)
            }
        }
    }
}

private struct RegionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(text)
                    .ppStyleFont(.scdream(.light, size: 10))
                    .foregroundStyle(Color.mainGray)
                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.mainGray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(width: 60)
            .background(Color.subWhite)
            .cornerRadius(17)
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.mainGray5)
            }
        }
    }
}

private struct HomeRegionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let regions: [RegionList]
    @Binding var selectedRegion: RegionList?
    @Binding var selectedDistrict: String?

    private let backFont: Font = .system(size: 17, weight: .bold)
    private let buttonFont: Font = .scdream(.regular, size: 12)
    private let rowHeight: CGFloat = 46
    private let dividerHeight: CGFloat = 1.5

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("지역")
                        .foregroundStyle(Color.mainBlack)
                        .ppStyleFont(.scdream(.bold, size: 17))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(backFont)
                    }
                    .accessibilityIdentifier("home_sheet_close_button")
                }
                .padding(.top, 28)

                Rectangle()
                    .frame(height: dividerHeight)
                    .foregroundStyle(Color.mainGray3)
                    .padding(.top, 30)

                HStack(spacing: 0) {
                    List(regions) { region in
                        VStack(spacing: 0) {
                            Button {
                                selectedRegion = region
                                selectedDistrict = region.districtList.first
                            } label: {
                                HStack(spacing: 0) {
                                    Spacer()
                                    Text(region.region)
                                        .foregroundStyle(selectedRegion == region ? Color.mainOrange : Color.mainGray)
                                        .font(buttonFont)
                                    Spacer()
                                }
                            }
                            .frame(height: rowHeight)
                            .accessibilityIdentifier("home_region_\(region.region)")
                        }
                        .listRowBackground(selectedRegion == region ? Color.subWhite : Color.mainGray4)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .frame(width: 65)
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)

                    if let selectedRegion {
                        List(selectedRegion.districtList, id: \.self) { district in
                            Button {
                                selectedDistrict = district
                                dismiss()
                            } label: {
                                HStack(spacing: 0) {
                                    Text(district)
                                        .foregroundStyle(selectedDistrict == district ? Color.mainOrange : Color.mainGray)
                                        .font(buttonFont)
                                    Spacer()
                                }
                            }
                            .frame(height: rowHeight)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier("home_district_\(district)")
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .frame(height: 300)
            }
            .padding(.horizontal, 28)
        }
        .presentationDragIndicator(.visible)
    }
}

private enum ImagePresent {
    case bestPopupCell
    case comingPopupCell
    case gridPopupCell

    var size: CGSize {
        switch self {
        case .bestPopupCell:
            CGSize(width: 194, height: 271)
        case .comingPopupCell:
            CGSize(width: 283, height: 138)
        case .gridPopupCell:
            CGSize(width: (UIScreen.main.bounds.width - 15 * 3) / 2, height: 217)
        }
    }
}

private extension KFImage {
    func downSampled(_ present: ImagePresent, scale: CGFloat = UIScreen.main.scale) -> some View {
        setProcessor(DownsamplingImageProcessor(size: present.size))
            .scaleFactor(scale)
            .cacheOriginalImage()
            .resizable()
    }
}

@Observable
private final class HomeViewState {
    var nickname = "닉네임"
    var bestPopups: [Popup] = [.popupMock, .popupMock2]
    var comingPopups: [Popup] = [.popupMock2, .popupMock]
    var gridPopups: [Popup] = [.popupMock, .popupMock2, .popupMock, .popupMock2]
    var regions: [RegionList] = [
        RegionList(region: "전체", districtList: ["전체"]),
        RegionList(region: "서울", districtList: ["전체", "성동구", "강남구", "마포구"]),
        RegionList(region: "부산", districtList: ["전체", "해운대구", "수영구"]),
    ]
    var selectedRegion: RegionList?
    var selectedDistrict: String?
    var selectedOption: SortButton.SortOption = .newest
    var showRegionSheet = false
    var showSortSheet = false

    init() {
        selectedRegion = regions.first
        selectedDistrict = regions.first?.districtList.first
    }

    func isLiked(popup: Popup) -> Bool {
        gridPopups.first(where: { $0.popupUuid == popup.popupUuid })?.isFavorited ?? popup.isFavorited
    }

    func toggleLike(popup: Popup) {
        for index in gridPopups.indices where gridPopups[index].popupUuid == popup.popupUuid {
            gridPopups[index].isFavorited.toggle()
            if gridPopups[index].isFavorited {
                gridPopups[index].favoriteCount += 1
            } else {
                gridPopups[index].favoriteCount = max(0, gridPopups[index].favoriteCount - 1)
            }
        }
    }
}
