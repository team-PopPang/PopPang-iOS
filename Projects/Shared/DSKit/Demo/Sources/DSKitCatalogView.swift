import DSKit
import SheetKit
import SwiftUI

struct DSKitCatalogView: View {
    @State private var nickname: String = ""
    @State private var searchText: String = ""
    @State private var keywordText: String = ""
    @State private var mapSearchText: String = ""
    @State private var catalogSheetDetent: BottomSheetDetent? = .medium
    @State private var dropdownSelection: String? = "전체"
    @State private var sortOption: SortButton.SortOption = .mostFavorited

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    tokenSection
                    buttonSection
                    tagAndDividerSection
                    textFieldSection
                    layoutSection
                    sheetSection
                    segmentedSection
                    calendarSection
                }
                .padding(.horizontal, .contentPadding)
                .padding(.vertical, 24)
            }
            .background(Color.mainGray4.ignoresSafeArea())
            .navigationTitle("DSKit Catalog")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("현재 DSKit에 들어있는 UI")
                .ppStyleFont(.systemFont(ofSize: 32, weight: .bold), lineHeight: 1.2)
                .foregroundStyle(Color.mainBlack)

            Text("디자이너가 바로 확인할 수 있도록 현재 구현된 토큰과 컴포넌트를 한 화면에 모았습니다.")
                .ppStyleFont(.scdream(.regular, size: 13))
                .foregroundStyle(Color.mainGray)
        }
    }

    private var tokenSection: some View {
        catalogSection(
            title: "Design Tokens",
            items: [
                "PPColor: 역할별 색 (UIKit은 .uiColor)",
                "PPTextStyle / ppTextStyle: 글자 크기·행간·자간",
                "PPSpacing: 여백·간격",
                "PPRadius: 모서리"
            ]
        ) {
            VStack(alignment: .leading, spacing: 24) {
                colorTokens
                textStyleTokens
                spacingTokens
                radiusTokens
            }
        }
    }

    private var colorTokens: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), alignment: .top)],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(Self.colorTokenItems) { token in
                colorSwatch(token.name, color: token.color)
            }
        }
    }

    private var textStyleTokens: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(PPTextStyle.allCases, id: \.self) { style in
                Text("\(String(describing: style)) · \(Int(style.size))pt 팝업스토어")
                    .ppTextStyle(style)
                    .foregroundStyle(PPColor.textPrimary)
            }
        }
    }

    private var spacingTokens: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Self.spacingTokenItems) { token in
                HStack(spacing: PPSpacing.s8) {
                    Text(token.name)
                        .ppTextStyle(.caption1)
                        .foregroundStyle(PPColor.textSecondary)
                        .frame(width: 120, alignment: .leading)

                    Rectangle()
                        .fill(PPColor.brand)
                        .frame(width: token.value, height: 12)
                }
            }
        }
    }

    private var radiusTokens: some View {
        HStack(spacing: PPSpacing.s12) {
            ForEach(Self.radiusTokenItems) { token in
                VStack(spacing: PPSpacing.s5) {
                    RoundedRectangle(cornerRadius: token.value)
                        .fill(PPColor.backgroundSecondary)
                        .overlay {
                            RoundedRectangle(cornerRadius: token.value)
                                .stroke(PPColor.border, lineWidth: 1)
                        }
                        .frame(width: 64, height: 64)

                    Text(token.name)
                        .ppTextStyle(.caption1)
                        .foregroundStyle(PPColor.textSecondary)
                }
            }
        }
    }

    private var buttonSection: some View {
        catalogSection(
            title: "Buttons",
            items: [
                "PPButtonStyle (.ppPrimary / .ppOutline / .ppText / .pp)",
                "MainOrangeButton",
                "IconButton",
                "DropDownView",
                "SortButton",
                "SocialLoginButton"
            ]
        ) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Button("ppPrimary") {}
                        .buttonStyle(.ppPrimary)

                    Button("ppOutline") {}
                        .buttonStyle(.ppOutline)

                    HStack(spacing: PPSpacing.s8) {
                        Button("medium") {}
                            .buttonStyle(.pp(.primary, size: .medium, fillsWidth: false))

                        Button("small") {}
                            .buttonStyle(.pp(.outline, size: .small, fillsWidth: false))

                        Button("ppText") {}
                            .buttonStyle(.ppText)
                    }

                    Button("비활성") {}
                        .buttonStyle(.ppPrimary)
                        .disabled(true)
                }

                Divider()

                MainOrangeButton(buttonTitle: "다음") {}

                MainOrangeButton(
                    buttonTitle: "반전 버튼",
                    isReversed: true
                ) {}

                HStack(spacing: 4) {
                    IconButton(image: "bell", systemImage: true) {}
                    IconButton(image: "heart", systemImage: true) {}
                    IconButton(image: "line.3.horizontal.decrease", systemImage: true) {}
                }

                DropDownView(
                    options: ["전체", "서울", "부산", "진주"],
                    maxWidth: .infinity,
                    selection: $dropdownSelection,
                    overlay: true
                )

                SortButton(selectedOption: $sortOption) {}

                VStack(spacing: 12) {
                    SocialLoginButton(type: .kakao) {}
                    SocialLoginButton(type: .apple) {}
                    SocialLoginButton(type: .google) {}
                }
            }
        }
    }

    private var tagAndDividerSection: some View {
        catalogSection(
            title: "Tags & Divider",
            items: [
                "PopupCategoryTag",
                "ShadowDivider",
            ]
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    PopupCategoryTag(text: "전시")
                    PopupCategoryTag(text: "캐릭터")
                    PopupCategoryTag(text: "브랜드")
                }

                ShadowDivider()
            }
        }
    }

    private var textFieldSection: some View {
        catalogSection(
            title: "Text Fields",
            items: [
                "RoundedTextField",
                "SearchTextField",
                "KeywordTextField",
                "MapSearchTextField",
            ]
        ) {
            VStack(spacing: 14) {
                RoundedTextField(
                    placeholder: "닉네임을 입력해주세요",
                    text: $nickname,
                    validationState: .none
                )

                SearchTextField(
                    placeholder: "궁금한 장소를 검색해보세요",
                    text: $searchText
                )

                KeywordTextField(
                    placeholder: "궁금한 팝업을 검색해보세요",
                    text: $keywordText
                )

                MapSearchTextField(
                    placeholder: "지도에서 팝업을 검색해보세요",
                    text: $mapSearchText
                )
            }
        }
    }

    private var layoutSection: some View {
        let categories = ["전시", "패션", "식음료", "로컬", "굿즈"]
        let recentKeywords = ["성수", "더현대", "산리오"]

        return catalogSection(
            title: "Layout",
            items: [
                "CategoryButton",
                "FlowLayout",
                "SearchFlowButton",
                "SearchFlowLayout",
                "CustomNavigationBar",
            ]
        ) {
            VStack(alignment: .leading, spacing: 20) {
                CustomNavigationBar {
                    HStack {
                        Image(systemName: "chevron.left")
                        Spacer()
                        Text("커스텀 네비게이션")
                            .ppStyleFont(.scdream(.bold, size: 16))
                        Spacer()
                        Image(systemName: "bell")
                    }
                    .foregroundStyle(Color.mainBlack)
                }
                .background(Color.subWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                FlowLayout(categories, id: \.self) { category in
                    CategoryButton(
                        title: category,
                        isSelected: category == "전시"
                    ) {}
                }
                .frame(height: 100)

                SearchFlowLayout {
                    ForEach(recentKeywords, id: \.self) { keyword in
                        SearchFlowButton(title: keyword) {} onRemove: {}
                            .padding(4)
                    }
                }
            }
        }
    }

    private var segmentedSection: some View {
        catalogSection(
            title: "Segmented Views",
            items: [
                "SegmentedControlView",
                "DetailSegmentedControlView",
            ]
        ) {
            VStack(spacing: 24) {
                SegmentedControlView(
                    segments: ["홈", "리뷰"],
                    views: [
                        AnyView(segmentCard("홈 콘텐츠")),
                        AnyView(segmentCard("리뷰 콘텐츠")),
                    ],
                    background: .mainGray2,
                    foreground: .mainOrange,
                    height: 3
                )
                .frame(height: 160)

                DetailSegmentedControlView(
                    segments: ["공지", "이벤트", "쿠폰"],
                    views: [
                        AnyView(segmentCard("공지 탭")),
                        AnyView(segmentCard("이벤트 탭")),
                        AnyView(segmentCard("쿠폰 탭")),
                    ],
                    background: .mainGray5,
                    foreground: .mainOrange,
                    height: 3,
                    font: .scdream(.medium, size: 12)
                )
                .frame(height: 180)
            }
        }
    }

    private var sheetSection: some View {
        catalogSection(
            title: "Sheet",
            items: [
                "SheetKit bottomSheet(detent:)",
                "ppBottomSheetStyle",
            ]
        ) {
            // 시트는 붙인 뷰 안에서 움직이므로, 작은 화면 틀에 붙여 모양과 높이 단계를 확인한다.
            ZStack {
                Color.mainGray4

                if catalogSheetDetent == nil {
                    Button("시트 열기") {
                        catalogSheetDetent = .medium
                    }
                    .ppStyleFont(.systemFont(ofSize: 16, weight: .semibold), lineHeight: 1.2)
                    .foregroundStyle(Color.mainWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.mainBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(height: 320)
            .bottomSheet(detent: $catalogSheetDetent, detents: [.fraction(0.3), .medium, .large]) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ppBottomSheetStyle")
                        .ppStyleFont(.scdream(.bold, size: 18))
                        .foregroundStyle(Color.mainBlack)

                    Text("손잡이를 끌거나 눌러 높이를 바꾸고, 아래로 끝까지 내리면 닫힙니다.")
                        .ppStyleFont(.scdream(.regular, size: 13))
                        .foregroundStyle(Color.mainGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .ppBottomSheetStyle()
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var calendarSection: some View {
        let today = Calendar.current.startOfDay(for: .init())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today

        return catalogSection(
            title: "Calendar",
            items: [
                "CustomCalendar",
            ]
        ) {
            CustomCalendar(
                eventCounts: [
                    today: 2,
                    tomorrow: 1,
                    dayAfterTomorrow: 4,
                ]
            ) { _ in }
        }
    }

    private func catalogSection<Content: View>(
        title: String,
        items: [String],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .ppStyleFont(.scdream(.bold, size: 18))
                .foregroundStyle(Color.mainBlack)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .ppStyleFont(.scdream(.regular, size: 13))
                        .foregroundStyle(Color.mainGray)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(Color.subWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mainGray5, lineWidth: 1)
            }
        }
    }

    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .overlay {
                    // 흰색 계열 색도 카드 배경과 구분되게 테두리를 그린다.
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mainGray5, lineWidth: 1)
                }
                .frame(width: 64, height: 64)

            Text(name)
                .ppStyleFont(.scdream(.regular, size: 11))
                .foregroundStyle(Color.mainGray)
        }
    }

    private func segmentCard(_ title: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.mainGray4)
            .overlay {
                Text(title)
                    .ppStyleFont(.scdream(.medium, size: 13))
                    .foregroundStyle(Color.mainBlack)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ColorToken: Identifiable {
    let name: String
    let color: Color

    var id: String { name }
}

private struct ValueToken: Identifiable {
    let name: String
    let value: CGFloat

    var id: String { name }
}

private extension DSKitCatalogView {
    static let colorTokenItems: [ColorToken] = [
        ColorToken(name: "brand", color: PPColor.brand),
        ColorToken(name: "brandSubtle", color: PPColor.brandSubtle),
        ColorToken(name: "textPrimary", color: PPColor.textPrimary),
        ColorToken(name: "textStrong", color: PPColor.textStrong),
        ColorToken(name: "textSecondary", color: PPColor.textSecondary),
        ColorToken(name: "textTertiary", color: PPColor.textTertiary),
        ColorToken(name: "textOnBrand", color: PPColor.textOnBrand),
        ColorToken(name: "background", color: PPColor.background),
        ColorToken(name: "backgroundSecondary", color: PPColor.backgroundSecondary),
        ColorToken(name: "border", color: PPColor.border),
        ColorToken(name: "divider", color: PPColor.divider),
        ColorToken(name: "error", color: PPColor.error),
        ColorToken(name: "success", color: PPColor.success),
    ]

    static let spacingTokenItems: [ValueToken] = [
        ValueToken(name: "s4", value: PPSpacing.s4),
        ValueToken(name: "s5", value: PPSpacing.s5),
        ValueToken(name: "s8", value: PPSpacing.s8),
        ValueToken(name: "s10", value: PPSpacing.s10),
        ValueToken(name: "s12", value: PPSpacing.s12),
        ValueToken(name: "s15", value: PPSpacing.s15),
        ValueToken(name: "s20", value: PPSpacing.s20),
        ValueToken(name: "s24", value: PPSpacing.s24),
        ValueToken(name: "screenHorizontal", value: PPSpacing.screenHorizontal),
    ]

    static let radiusTokenItems: [ValueToken] = [
        ValueToken(name: "small", value: PPRadius.small),
        ValueToken(name: "medium", value: PPRadius.medium),
        ValueToken(name: "large", value: PPRadius.large),
    ]
}
