import DSKit
import SwiftUI

struct DSKitCatalogView: View {
    @State private var nickname: String = ""
    @State private var searchText: String = ""
    @State private var keywordText: String = ""
    @State private var mapSearchText: String = ""
    @State private var showsMapSheet = false
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
                "Color.hex / uiColor",
                "UIFont.scdream / Font.scdream",
                "ppStyleFont / ppStyle / ppStyleFontFixedSpacing",
                "CGFloat.contentPadding / cornerRadius",
                "Font.title1 / caption1 / largeTitle"
            ]
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    colorSwatch("mainOrange", color: .mainOrange)
                    colorSwatch("mainGreen", color: .mainGreen)
                    colorSwatch("mainGray5", color: .mainGray5)
                    colorSwatch("categoryOrange", color: .categoryOrange)
                }

                Text("S-CoreDream Bold 17")
                    .ppStyleFont(.scdream(.bold, size: 17))
                    .foregroundStyle(Color.mainBlack)

                Text("팝팡 스타일 본문 샘플")
                    .ppStyleFont(.scdream(.regular, size: 15))
                    .foregroundStyle(Color.mainGray)
            }
        }
    }

    private var buttonSection: some View {
        catalogSection(
            title: "Buttons",
            items: [
                "MainOrangeButton",
                "IconButton",
                "DropDownView",
                "SortButton",
                "SocialLoginButton"
            ]
        ) {
            VStack(alignment: .leading, spacing: 20) {
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
                "mapSheet",
            ]
        ) {
            Button("맵 시트 샘플 열기") {
                showsMapSheet = true
            }
            .ppStyleFont(.systemFont(ofSize: 16, weight: .semibold), lineHeight: 1.2)
            .foregroundStyle(Color.mainWhite)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mainBlack)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .sheet(isPresented: $showsMapSheet) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MapSheet Sample")
                        .ppStyleFont(.scdream(.bold, size: 18))
                        .foregroundStyle(Color.mainBlack)

                    Text("탭바와 safe area를 고려해 하단 영역을 보정하는 DSKit modifier입니다.")
                        .ppStyleFont(.scdream(.regular, size: 13))
                        .foregroundStyle(Color.mainGray)

                    Spacer()
                }
                .padding(24)
                .presentationDetents([.medium])
                .modifier(MapSheetModifier())
            }
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
