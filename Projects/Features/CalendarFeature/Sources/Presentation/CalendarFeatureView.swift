import Compound
import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI

public struct CalendarFeatureView: View {
    @State private var compound: CalendarFeatureCompound
    @State private var sheetRoute: CalendarFeatureCompound.SheetRoute?

    private let onShowAlert: (String) -> Void
    private let onSelectPopup: (String, Popup) -> Void

    public init(
        userUuid: String = "demo-user",
        onShowAlert: @escaping (String) -> Void = { _ in },
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
    ) {
        _compound = State(wrappedValue: CalendarFeatureCompound(userUuid: userUuid))
        self.onShowAlert = onShowAlert
        self.onSelectPopup = onSelectPopup
    }

    public var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar {
                Text("캘린더")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)

                Spacer()

                IconButton {
                    onShowAlert(compound.state.userUuid)
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CustomCalendar(
                        eventCounts: compound.state.popupEventCounts,
                        onDateSelected: { date in
                            compound.send(.dateSelected(date))
                        }
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 15)

                    CalendarPopupListView(
                        userUuid: compound.state.userUuid,
                        date: compound.state.selectedDate,
                        popups: compound.state.selectedPopups,
                        regions: compound.state.regions,
                        selectedRegion: compound.state.selectedRegion,
                        selectedDistrict: compound.state.selectedDistrict,
                        selectedOption: compound.state.selectedOption,
                        isLoading: compound.state.isLoading,
                        errorMessage: compound.state.errorMessage,
                        onRegionTapped: {
                            compound.send(.regionSheetPresented(true))
                        },
                        onSortTapped: {
                            compound.send(.sortSheetPresented(true))
                        },
                        onToggleLike: { popup in
                            compound.send(.toggleLike(popup))
                        },
                        onSelectPopup: { popup in
                            onSelectPopup(compound.state.userUuid, popup)
                        }
                    )
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(colors: [.black, .clear, .clear, .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .applyShadow(
                                color: .black,
                                alpha: 0.05,
                                x: 0,
                                y: -4,
                                blur: 8
                            )
                    )
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .task {
            compound.send(.onAppear)
        }
        .trigger(of: compound, \.$presentedSheet) { route in
            sheetRoute = route
        }
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .region:
                CalendarRegionSheet(
                    regions: compound.state.regions,
                    selectedRegion: selectedRegionBinding,
                    selectedDistrict: selectedDistrictBinding
                )
            case .sort:
                SortButtonSheet(selectedOption: selectedOptionBinding)
            }
        }
    }
}

private extension CalendarFeatureView {
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
            }
        )
    }

    var selectedOptionBinding: Binding<SortButton.SortOption> {
        Binding(
            get: { compound.state.selectedOption },
            set: { compound.send(.sortOptionSelected($0)) }
        )
    }
}

private struct CalendarPopupListView: View {
    let userUuid: String
    let date: Date
    let popups: [Popup]
    let regions: [RegionList]
    let selectedRegion: RegionList?
    let selectedDistrict: String?
    let selectedOption: SortButton.SortOption
    let isLoading: Bool
    let errorMessage: String?
    let onRegionTapped: () -> Void
    let onSortTapped: () -> Void
    let onToggleLike: (Popup) -> Void
    let onSelectPopup: (Popup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainBlack)

                Spacer()

                RegionButton(text: "지역") {
                    onRegionTapped()
                }
                .padding(.leading, -10)

                SortButton(
                    selectedOption: .constant(selectedOption),
                    action: onSortTapped
                )
            }
            .padding(.top, 20)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }

            if let errorMessage {
                Text(errorMessage)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }

            if popups.isEmpty && !isLoading {
                Text("선택한 날짜에 팝업이 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(popups.enumerated()), id: \.element.id) { index, popup in
                            CalendarPopupCell(
                                popup: popup,
                                isLiked: popup.isFavorited,
                                onToggleLike: {
                                    onToggleLike(popup)
                                }
                            )
                            .onTapGesture {
                                onSelectPopup(popup)
                            }

                            if index != popups.count - 1 {
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.subWhite)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ko_KR")
        dayFormatter.dateFormat = "d일 (E)"
        return dayFormatter.string(from: date)
    }
}

private struct CalendarPopupCell: View {
    let popup: Popup
    let isLiked: Bool
    let onToggleLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .downSampled(.calendarPopupCell)
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

                        Button {
                            onToggleLike()
                        } label: {
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
                        .foregroundStyle(isLiked ? Color.mainOrange : Color.mainGray)
                    }
                }
                .padding(.leading, 18)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
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

private struct CalendarRegionSheet: View {
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
    case calendarPopupCell

    var size: CGSize {
        switch self {
        case .calendarPopupCell:
            CGSize(width: 106, height: 133)
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
