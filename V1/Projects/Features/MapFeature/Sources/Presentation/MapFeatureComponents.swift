import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI
import UIKit

struct MapRegionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(text)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.subBlack)

                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.subBlack)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(width: 80, height: 45)
            .background(Color.subWhite)
            .cornerRadius(3, corners: [.topLeft, .bottomLeft])
        }
        .buttonStyle(.plain)
    }
}

struct MapSortButton: View {
    @Binding var selectedOption: MapSortOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(selectedOption.title)
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
            .frame(width: 80)
            .background(Color.subWhite)
            .cornerRadius(17)
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.mainGray5)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MapSortButtonSheet: View {
    @Binding var selectedOption: MapSortOption
    let onDismiss: () -> Void
    let onSortSelected: (MapSortOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("정렬")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.bold, size: 17))

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(.system(size: 21, weight: .regular))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(MapSortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        onSortSelected(option)
                    } label: {
                        DSKitResource.image(selectedOption == option ? "circle_filled" : "circle")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(selectedOption == option ? .orange : .gray)

                        Text(option.title)
                            .foregroundStyle(Color.mainBlack)
                            .ppStyleFont(.scdream(.regular, size: 15))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 40)
                }
            }
            .padding(.top, 28)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 28)
    }
}

struct MapRegionSheet: View {
    let regions: [RegionList]
    let selectedRegion: RegionList?
    let selectedDistrict: String?
    let onDismiss: () -> Void
    let onRegionSelected: (RegionList) -> Void
    let onDistrictSelected: (String) -> Void

    private let rowHeight: CGFloat = 46
    private let dividerHeight: CGFloat = 1.5

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("지역")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.bold, size: 17))

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(.system(size: 17, weight: .bold))
                }
            }

            Rectangle()
                .frame(height: dividerHeight)
                .foregroundStyle(Color.mainGray3)
                .padding(.top, 30)

            HStack(spacing: 0) {
                List(regions) { region in
                    Button {
                        onRegionSelected(region)
                    } label: {
                        HStack(spacing: 0) {
                            Spacer()
                            Text(region.region)
                                .foregroundStyle(selectedRegion == region ? Color.mainOrange : Color.mainGray)
                                .font(.scdream(.regular, size: 12))
                            Spacer()
                        }
                    }
                    .frame(height: rowHeight)
                    .listRowBackground(selectedRegion == region ? Color.subWhite : Color.mainGray4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                .frame(width: 65)
                .listStyle(.plain)
                .scrollIndicators(.hidden)

                Divider()

                if let selectedRegion {
                    List(selectedRegion.districtList, id: \.self) { district in
                        VStack(spacing: 0) {
                            Button {
                                Logger.d("선택된 지역: \(selectedRegion.region), 구: \(district)")
                                onDistrictSelected(district)
                            } label: {
                                HStack(spacing: 0) {
                                    Text(district)
                                        .foregroundStyle(selectedDistrict == district ? Color.mainOrange : .primary)
                                        .font(.scdream(.regular, size: 12))
                                        .padding(.leading, 20)
                                    Spacer()
                                }
                            }
                            .frame(height: rowHeight)

                            Divider()
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                }
            }
            .frame(height: CGFloat(max(regions.count, 1)) * rowHeight)

            Rectangle()
                .frame(height: dividerHeight)
                .foregroundStyle(Color.mainGray3)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 28)
    }
}

struct TrendingCategoryScrollView: View {
    let categories: [Recommend]
    let selectedCategoryId: Int?
    let onSelect: (Recommend) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories) { category in
                    TrendingCategoryChip(
                        category: category,
                        isSelected: selectedCategoryId == category.id
                    ) {
                        onSelect(category)
                    }
                }
            }
        }
    }
}

struct TrendingCategoryChip: View {
    let category: Recommend
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.recommendName)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(isSelected ? Color.subWhite : Color.mainBlack)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.mainOrange : Color.subWhite))
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.mainGray6, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(category.recommendName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct MapListPopupCell: View {
    let popup: Popup
    let onToggleLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)

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

                    Spacer()

                    HStack(spacing: 5) {
                        Spacer()

                        DSKitResource.image("viewCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)

                        Text("\(popup.viewCount)")
                            .ppStyleFont(.scdream(.regular, size: 9))

                        Button(action: onToggleLike) {
                            HStack(spacing: 5) {
                                DSKitResource.image("favoriteCount")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)

                                Text("\(popup.favoriteCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(popup.isFavorited ? Color.mainOrange : Color.mainGray)
                    }
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}

struct DetailSheetView: View {
    let popup: Popup
    let onDismiss: () -> Void
    let onDetailTap: () -> Void

    private let imageWidth: CGFloat = UIScreen.main.bounds.width - 30

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(popup.recommendList.first ?? "")
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainGray9)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(.system(size: 11, weight: .regular))
                            .frame(width: 27, height: 27)
                            .background(Color.mainGray5)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)

                HStack(spacing: 0) {
                    Text(popup.name)
                        .ppStyleFont(.scdream(.bold, size: 18))
                        .foregroundStyle(Color.mainBlack)

                    Spacer()
                }

                VStack(spacing: 5) {
                    detailRow(title: "운영 장소", value: popup.roadAddress)

                    HStack(spacing: 5) {
                        Text("운영 날짜")
                            .ppStyleFont(.scdream(.light, size: 12))
                            .foregroundStyle(Color.mainGray)

                        HStack(spacing: 3) {
                            Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                            Text("-")
                            Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                        }
                        .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                        .foregroundStyle(Color.mainBlack)

                        Spacer()
                    }

                    HStack(spacing: 5) {
                        if popup.openTime != nil, popup.closeTime != nil {
                            Text("운영 시간")
                                .ppStyleFont(.scdream(.light, size: 12))
                                .foregroundStyle(Color.mainGray)
                        }

                        HStack(spacing: 2) {
                            if let openTime = popup.openTime, let closeTime = popup.closeTime {
                                Text(openTime)
                                Text("-")
                                Text(closeTime)
                            }
                        }
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)

                        Spacer()
                    }
                }
                .padding(.top, 10)

                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageWidth, height: 182)
                    .clipped()
                    .allowsHitTesting(false)
                    .padding(.top, 20)
            }
            .padding(.horizontal, .contentPadding)
        }
        .onTapGesture(perform: onDetailTap)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .ppStyleFont(.scdream(.light, size: 12))
                .foregroundStyle(Color.mainGray)

            Text(value)
                .ppStyleFont(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.leading, 5)

            Spacer()
        }
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
