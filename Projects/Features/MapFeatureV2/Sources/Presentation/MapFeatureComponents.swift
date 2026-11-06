import Core
import Domain
import DSKit
import Kingfisher
import SheetKit
import SwiftUI
import UIKit

// MARK: - 색

/// 지도 화면 색. 피그마 "팝팡 리뉴얼 최종"(2467:10300)의 지도 화면 기준이다. 메인 색은 앱과 같은 주황이다.
enum MapColor {
    static let brand = PPColor.brand
    static let brandSubtle = PPColor.brandSubtle
    static let text = Color(hex: "#191919")
    static let chipText = Color(hex: "#333333")
    static let secondaryText = Color(hex: "#8A8A8A")
    static let border = Color(hex: "#E3E3E3")
    static let divider = Color(hex: "#F0F0F0")
    static let segment = Color(hex: "#F4F4F4")
    static let dark = Color(hex: "#191919")
    static let statusText = Color(hex: "#089700")
    static let statusBackground = Color(hex: "#F4FFEE")
    static let categoryText = Color(hex: "#D9530B")
    static let categoryBackground = Color(hex: "#FDEFE6")
    static let regionText = Color(hex: "#AAAAAA")
    static let regionBackground = Color(hex: "#F4F4F4")
}

/// API가 아직 없는 기능의 글자 뒤에 "(x)"를 붙인다(2026-11-06 결정: 화면은 먼저 만들고 텍스트로 표시).
func mapUnsupported(_ text: String, supported: Bool) -> String {
    supported ? text : "\(text) (x)"
}

// MARK: - 검색창

struct MapSearchBar: View {
    let regionTitle: String
    /// 목록을 끝까지 펼친 화면(③)에서는 흰 시트 위라 회색 바탕에 그림자를 뺀다.
    var isOnList = false
    @Binding var text: String
    let onRegionTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onRegionTap) {
                HStack(spacing: 4) {
                    DSKitResource.image("map")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(MapColor.text)
                    Text(regionTitle)
                        .font(.scdream(.bold, size: 14))
                        .foregroundStyle(MapColor.text)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MapColor.text)
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(MapColor.border)
                .frame(width: 1, height: 20)

            TextField(
                "",
                text: $text,
                prompt: Text(mapUnsupported(String(localized: "팝업, 브랜드, 지역 검색", bundle: .module), supported: MapAPISupport.keyword))
                    .foregroundStyle(MapColor.secondaryText)
            )
            .font(.scdream(.regular, size: 14))
            .tint(MapColor.text)
            .submitLabel(.search)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(MapColor.text)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(isOnList ? MapColor.segment : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isOnList ? 0 : 0.08), radius: 8, y: 2)
    }
}

// MARK: - 필터 칩

/// 칩을 눌러 여는 드롭다운 메뉴 종류.
enum MapMenu: Hashable {
    case category
    case status
    case period
}

struct MapFilterChipRow: View {
    let filter: MapPopupFilter
    let openMenu: MapMenu?
    let onFilterTap: () -> Void
    let onMenuTap: (MapMenu) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button(action: onFilterTap) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(filter.activeCount > 0 ? MapColor.brand : MapColor.chipText)
                        .frame(width: 35, height: 30)
                        .background(chipBackground(isActive: filter.activeCount > 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("필터", bundle: .module))

                chip(.category, title: categoryTitle, isActive: filter.categoryIds.isEmpty == false)
                chip(.status, title: statusTitle, isActive: filter.status != .all)
                chip(.period, title: periodTitle, isActive: filter.period != .all)
            }
            .padding(.horizontal, 16)
        }
    }

    private var categoryTitle: String {
        mapUnsupported(String(localized: "카테고리", bundle: .module), supported: MapAPISupport.category)
    }

    private var statusTitle: String {
        let title = filter.status == .all ? String(localized: "상태", bundle: .module) : filter.status.title
        return mapUnsupported(title, supported: MapAPISupport.status)
    }

    private var periodTitle: String {
        let title = filter.period == .all ? String(localized: "기간", bundle: .module) : filter.period.title
        return mapUnsupported(title, supported: MapAPISupport.period)
    }

    private func chip(_ menu: MapMenu, title: String, isActive: Bool) -> some View {
        Button {
            onMenuTap(menu)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.scdream(.medium, size: 13))
                    .lineLimit(1)
                Image(systemName: openMenu == menu ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isActive ? MapColor.brand : MapColor.chipText)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(chipBackground(isActive: isActive))
        }
        .buttonStyle(.plain)
        .anchorPreference(key: MapMenuAnchorKey.self, value: .bounds) { [menu: $0] }
    }

    private func chipBackground(isActive: Bool) -> some View {
        Capsule()
            .fill(isActive ? MapColor.brandSubtle : Color.white)
            .overlay(Capsule().strokeBorder(isActive ? MapColor.brand : Color.clear, lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }
}

/// 칩 위치. 드롭다운 메뉴를 그 칩 아래에 띄울 때 쓴다.
struct MapMenuAnchorKey: PreferenceKey {
    static let defaultValue: [MapMenu: Anchor<CGRect>] = [:]

    static func reduce(value: inout [MapMenu: Anchor<CGRect>], nextValue: () -> [MapMenu: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - 드롭다운 메뉴 (⑤ 개별 필터)

struct MapDropdownMenu: View {
    let menu: MapMenu
    let categories: [Recommend]
    let filter: MapPopupFilter
    let onFilterChange: (MapPopupFilter) -> Void
    let onClose: () -> Void

    @State private var draftCategoryIds: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            switch menu {
            case .category:
                categoryMenu
            case .status:
                ForEach(MapStatusFilter.allCases, id: \.self) { status in
                    option(status.title, isSelected: filter.status == status) {
                        var next = filter
                        next.status = status
                        onFilterChange(next)
                    }
                }
            case .period:
                // 직접 선택(달력)은 API가 생긴 뒤에 붙인다.
                ForEach(MapPeriodFilter.allCases.filter { $0 != .custom }, id: \.self) { period in
                    option(period.title, isSelected: filter.period == period) {
                        var next = filter
                        next.period = period
                        onFilterChange(next)
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 220)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MapColor.divider))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .onAppear {
            draftCategoryIds = filter.categoryIds
        }
    }

    private var categoryMenu: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories) { category in
                        option(category.recommendName, isSelected: draftCategoryIds.contains(category.id)) {
                            if draftCategoryIds.contains(category.id) {
                                draftCategoryIds.remove(category.id)
                            } else {
                                draftCategoryIds.insert(category.id)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 252)

            HStack(spacing: 6) {
                Button {
                    draftCategoryIds = []
                } label: {
                    Text("초기화", bundle: .module)
                        .font(.scdream(.medium, size: 14))
                        .foregroundStyle(MapColor.chipText)
                        .frame(width: 70, height: 40)
                        .background(MapColor.segment, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    var next = filter
                    next.categoryIds = draftCategoryIds
                    onFilterChange(next)
                } label: {
                    Text(String(format: String(localized: "%lld개 적용", bundle: .module), draftCategoryIds.count))
                        .font(.scdream(.bold, size: 14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(MapColor.brand, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }

    private func option(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.scdream(isSelected ? .medium : .regular, size: 15))
                    .foregroundStyle(isSelected ? MapColor.brand : MapColor.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MapColor.brand)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 필터 시트 (④)

struct MapFilterSheet: View {
    let categories: [Recommend]
    let filter: MapPopupFilter
    let onApply: (MapPopupFilter) -> Void

    @State private var draft = MapPopupFilter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("필터", bundle: .module)
                    .font(.scdream(.bold, size: 20))
                    .foregroundStyle(MapColor.text)
                Spacer()
                Button {
                    draft = MapPopupFilter()
                } label: {
                    Text("초기화", bundle: .module)
                        .font(.scdream(.regular, size: 14))
                        .foregroundStyle(MapColor.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 28)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    section(String(localized: "상태", bundle: .module), supported: MapAPISupport.status) {
                        ForEach(MapStatusFilter.allCases.filter { $0 != .all }, id: \.self) { status in
                            chip(status.title, isSelected: draft.status == status) {
                                draft.status = draft.status == status ? .all : status
                            }
                        }
                    }

                    section(String(localized: "기간", bundle: .module), supported: MapAPISupport.period) {
                        ForEach(MapPeriodFilter.allCases.filter { $0 != .all && $0 != .custom }, id: \.self) { period in
                            chip(period.title, isSelected: draft.period == period) {
                                draft.period = draft.period == period ? .all : period
                            }
                        }
                    }

                    section(String(localized: "카테고리", bundle: .module), supported: MapAPISupport.category) {
                        ForEach(categories) { category in
                            chip(category.recommendName, isSelected: draft.categoryIds.contains(category.id)) {
                                if draft.categoryIds.contains(category.id) {
                                    draft.categoryIds.remove(category.id)
                                } else {
                                    draft.categoryIds.insert(category.id)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 20)
            }

            HStack(spacing: 10) {
                Button {
                    draft = MapPopupFilter()
                } label: {
                    Text("초기화", bundle: .module)
                        .font(.scdream(.medium, size: 15))
                        .foregroundStyle(MapColor.chipText)
                        .frame(width: 105, height: 51)
                        .background(MapColor.segment, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    onApply(draft)
                } label: {
                    // 결과 개수 미리 보기는 API가 생긴 뒤에 붙인다.
                    Text(String(localized: "팝업 (x)개 보기", bundle: .module))
                        .font(.scdream(.bold, size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 51)
                        .background(MapColor.brand, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .onAppear {
            draft = filter
        }
    }

    private func section<Content: View>(
        _ title: String,
        supported: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mapUnsupported(title, supported: supported))
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(MapColor.text)
            MapFlowLayout(spacing: 8, lineSpacing: 8) {
                content()
            }
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(.scdream(isSelected ? .bold : .regular, size: 14))
            }
            .foregroundStyle(isSelected ? MapColor.brand : MapColor.text)
            .padding(.horizontal, 14)
            .frame(height: 35)
            .background(
                Capsule()
                    .fill(isSelected ? MapColor.brandSubtle : Color.white)
                    .overlay(Capsule().strokeBorder(isSelected ? MapColor.brand : MapColor.border, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 칩을 줄 단위로 감싸 늘어놓는다. 카테고리가 많아지면 다음 줄로 넘긴다.
struct MapFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            width = max(width, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: min(width, maxWidth), height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - 배지

struct MapBadge: View {
    enum Style {
        case status
        case category
        case region
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(.scdream(.medium, size: 11))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(height: 17)
            .background(background, in: RoundedRectangle(cornerRadius: 5))
    }

    private var foreground: Color {
        switch style {
        case .status: MapColor.statusText
        case .category: MapColor.categoryText
        case .region: MapColor.regionText
        }
    }

    private var background: Color {
        switch style {
        case .status: MapColor.statusBackground
        case .category: MapColor.categoryBackground
        case .region: MapColor.regionBackground
        }
    }
}

extension Popup {
    /// 지도 API는 운영 중 팝업만 주므로 상태 배지는 "운영중"이다.
    /// 오늘 종료·D-n·오픈 예정 배지는 서버가 상태 값을 주면 바꾼다(MapAPISupport.status).
    var mapStatusText: String {
        String(localized: "운영중", bundle: .module)
    }

    var mapCategoryText: String? {
        recommendList.first
    }

    var mapRegionText: String {
        roadAddress.shortAddress
    }

    /// "26.10.22 ~ 26.10.29" 형태(피그마).
    var mapPeriodText: String {
        "\(DateFormatter.popupDateFormat.string(from: startDate)) ~ \(DateFormatter.popupDateFormat.string(from: endDate))"
    }
}

// MARK: - 사진

struct MapPopupThumbnail: View {
    let url: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        KFImage(URL(string: url ?? ""))
            .placeholder {
                Rectangle().fill(Color.mainGray3)
            }
            .resizable()
            .downSampled(.small)
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - 미리보기 카드 (②)

struct MapPreviewCard: View {
    let popup: Popup
    let isFavoriteInFlight: Bool
    let onClose: () -> Void
    let onToggleLike: () -> Void
    let onDetail: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                MapPopupThumbnail(url: popup.imageUrlList.first, width: 72, height: 92, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 8) {
                    MapBadgeRow(popup: popup)

                    Text(popup.name)
                        .font(.scdream(.extraBold, size: 16))
                        .foregroundStyle(MapColor.text)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Text(popup.mapPeriodText)
                        .font(.scdream(.regular, size: 13))
                        .foregroundStyle(MapColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 92)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MapColor.secondaryText)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("닫기", bundle: .module))
            }

            HStack(spacing: 8) {
                Button(action: onToggleLike) {
                    Image(systemName: popup.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(popup.isFavorited ? MapColor.brand : MapColor.text)
                        .frame(width: 43, height: 43)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(popup.isFavorited ? MapColor.brand : MapColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isFavoriteInFlight)
                .accessibilityLabel(Text("찜하기", bundle: .module))
                .accessibilityAddTraits(popup.isFavorited ? .isSelected : [])

                Button(action: onDetail) {
                    Text("상세보기", bundle: .module)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 43)
                        .background(MapColor.brand, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
    }
}

/// 운영중 · 카테고리 · 지역 배지 한 줄.
struct MapBadgeRow: View {
    let popup: Popup

    var body: some View {
        HStack(spacing: 4) {
            MapBadge(text: popup.mapStatusText, style: .status)
            if let category = popup.mapCategoryText {
                MapBadge(text: category, style: .category)
            }
            MapBadge(text: popup.mapRegionText, style: .region)
        }
    }
}

// MARK: - 목록 (③)

struct MapListHeader: View {
    let sort: MapSortOption
    let onSortChange: (MapSortOption) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("주변 팝업", bundle: .module)
                .font(.scdream(.bold, size: 18))
                .foregroundStyle(MapColor.text)
            Spacer()
            // 정렬은 시트 머리에만 둔다.
            Menu {
                ForEach(MapSortOption.allCases, id: \.self) { option in
                    Button {
                        onSortChange(option)
                    } label: {
                        if option == sort {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(sort.title)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .font(.scdream(.regular, size: 13))
                .foregroundStyle(MapColor.chipText)
            }
        }
    }
}

struct MapListPopupCell: View {
    let popup: Popup
    let isFavoriteInFlight: Bool
    let onToggleLike: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MapPopupThumbnail(url: popup.imageUrlList.first, width: 76, height: 100, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 6) {
                MapBadgeRow(popup: popup)

                Text(popup.name)
                    .font(.scdream(.extraBold, size: 16))
                    .foregroundStyle(MapColor.text)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(popup.mapPeriodText)
                    .font(.scdream(.regular, size: 13))
                    .foregroundStyle(MapColor.secondaryText)
            }
            .frame(height: 100)

            Spacer(minLength: 0)

            Button(action: onToggleLike) {
                Image(systemName: popup.isFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 19))
                    .foregroundStyle(popup.isFavorited ? MapColor.brand : MapColor.text)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(isFavoriteInFlight)
            .accessibilityLabel(Text("찜하기", bundle: .module))
            .accessibilityAddTraits(popup.isFavorited ? .isSelected : [])
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - 떠 있는 버튼

struct MapFloatingPill: View {
    enum Style {
        case light
        case dark
    }

    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.scdream(.bold, size: 14))
            }
            .foregroundStyle(style == .dark ? Color.white : MapColor.text)
            .padding(.horizontal, 18)
            .frame(height: 38)
            .background(Capsule().fill(style == .dark ? MapColor.dark : Color.white))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct MapCircleButton: View {
    let systemImage: String
    let accessibilityLabel: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MapColor.text)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 지역 시트

struct MapRegionSheet: View {
    let regions: [RegionList]
    let selectedRegion: RegionList?
    let selectedDistrict: String?
    let onRegionSelected: (RegionList) -> Void
    let onDistrictSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("지역", bundle: .module)
                .font(.scdream(.bold, size: 20))
                .foregroundStyle(MapColor.text)
                .padding(.top, 28)

            HStack(alignment: .top, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(regions) { region in
                            Button {
                                onRegionSelected(region)
                            } label: {
                                Text(region.region)
                                    .font(.scdream(selectedRegion == region ? .bold : .regular, size: 14))
                                    .foregroundStyle(selectedRegion == region ? MapColor.brand : MapColor.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(selectedRegion == region ? Color.white : MapColor.segment)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("map_region_\(region.region)")
                        }
                    }
                }
                .frame(width: 90)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(selectedRegion?.districtList ?? [], id: \.self) { district in
                            Button {
                                onDistrictSelected(district)
                            } label: {
                                HStack {
                                    Text(district)
                                        .font(.scdream(selectedDistrict == district ? .bold : .regular, size: 14))
                                        .foregroundStyle(selectedDistrict == district ? MapColor.brand : MapColor.text)
                                    Spacer()
                                    if selectedDistrict == district {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(MapColor.brand)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 46)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("map_district_\(district)")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct TabBarProxy: UIViewControllerRepresentable {
    var callback: (_ view: UIView, _ tabBar: UITabBar) -> Void

    final class ProxyController: UIViewController {
        var callback: (_ view: UIView, _ tabBar: UITabBar) -> Void = { _, _ in }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let tabBarController {
                callback(tabBarController.view, tabBarController.tabBar)
            }
        }
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ProxyController()
        controller.callback = callback
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
