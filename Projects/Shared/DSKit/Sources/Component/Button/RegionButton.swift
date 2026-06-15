import SwiftUI

public struct RegionButton: View {
    private let text: String
    private let action: () -> Void

    public init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
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

public struct RegionButtonSheet<Region: Identifiable & Equatable>: View {
    @Environment(\.dismiss) private var dismiss

    private let regions: [Region]
    @Binding private var selectedRegion: Region?
    @Binding private var selectedDistrict: String?
    private let regionTitle: (Region) -> String
    private let districts: (Region) -> [String]
    private let accessibilityPrefix: String

    private let backFont: Font = .system(size: 17, weight: .bold)
    private let buttonFont: Font = .scdream(.regular, size: 12)
    private let rowHeight: CGFloat = 46
    private let dividerHeight: CGFloat = 1.5
    @State private var pendingSelectedDistrict: String?

    public init(
        regions: [Region],
        selectedRegion: Binding<Region?>,
        selectedDistrict: Binding<String?>,
        accessibilityPrefix: String = "home",
        regionTitle: @escaping (Region) -> String,
        districts: @escaping (Region) -> [String]
    ) {
        self.regions = regions
        self._selectedRegion = selectedRegion
        self._selectedDistrict = selectedDistrict
        self.accessibilityPrefix = accessibilityPrefix
        self.regionTitle = regionTitle
        self.districts = districts
    }

    public var body: some View {
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
                    .accessibilityIdentifier("\(accessibilityPrefix)_sheet_close_button")
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
                                let firstDistrict = districts(region).first
                                pendingSelectedDistrict = firstDistrict

                                if districts(region).count <= 1 {
                                    selectedDistrict = firstDistrict
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Spacer()
                                    Text(regionTitle(region))
                                        .foregroundStyle(selectedRegion == region ? Color.mainOrange : Color.mainGray)
                                        .font(buttonFont)
                                    Spacer()
                                }
                            }
                            .frame(height: rowHeight)
                            .accessibilityIdentifier("\(accessibilityPrefix)_region_\(regionTitle(region))")
                        }
                        .listRowBackground(selectedRegion == region ? Color.subWhite : Color.mainGray4)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .frame(width: 65)
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)

                    Divider()

                    if let selectedRegion {
                        List(districts(selectedRegion), id: \.self) { district in
                            VStack(spacing: 0) {
                                Button {
                                    pendingSelectedDistrict = district
                                    selectedDistrict = district
                                    dismiss()
                                } label: {
                                    HStack(spacing: 0) {
                                        Text(district)
                                            .foregroundStyle((pendingSelectedDistrict ?? selectedDistrict) == district ? Color.mainOrange : Color.mainGray)
                                            .font(buttonFont)
                                            .padding(.leading, 20)
                                        Spacer()
                                    }
                                }
                                .frame(height: rowHeight)
                                .accessibilityIdentifier("\(accessibilityPrefix)_district_\(district)")

                                Divider()
                                    .padding(.leading, 0)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                        .scrollContentBackground(.hidden)
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
            .padding(.horizontal, 28)
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            pendingSelectedDistrict = selectedDistrict
        }
        .onChange(of: selectedDistrict) { _, district in
            pendingSelectedDistrict = district
        }
    }
}
