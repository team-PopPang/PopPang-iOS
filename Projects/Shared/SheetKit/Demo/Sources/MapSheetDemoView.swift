import SheetKit
import SwiftUI

/// 목록 시트 위에 겹쳐 띄우는 옵션 시트의 내용.
private enum OptionSheet: Identifiable {
    case region
    case sort
    case detail(Int)

    var id: String {
        switch self {
        case .region: "region"
        case .sort: "sort"
        case .detail(let index): "detail-\(index)"
        }
    }

    var title: String {
        switch self {
        case .region: "지역"
        case .sort: "정렬"
        case .detail(let index): "팝업 \(index)"
        }
    }
}

/// 지도 화면처럼 목록 시트 위에 옵션 시트를 겹쳐 띄우는 데모.
///
/// 아래를 확인한다.
/// - 시트 밖의 가짜 지도를 누르면 터치가 지도로 간다.
/// - 시트를 열고 닫거나 내용을 바꿔도 가로 길이가 그대로다.
/// - 검색창 키보드가 올라와도 시트가 밀리지 않는다.
/// - 목록 끝이 탭바에 가리지 않는다.
struct MapSheetDemoView: View {
    private static let coordinateSpace = "map"
    private static let regions = ["전체", "서울", "경기", "인천", "부산", "대구", "광주", "대전", "울산", "세종", "강원", "충북", "충남", "전북", "전남", "경북", "경남", "제주"]
    private static let sortOptions = ["가까운순", "최신순", "마감순", "찜순", "조회순"]

    @State private var listDetent: BottomSheetDetent? = .medium
    @State private var optionSheet: OptionSheet?
    @State private var optionDetent: BottomSheetDetent = .medium
    @State private var searchText = ""
    @State private var searchBarBottom: CGFloat = 0
    @State private var mapTapCount = 0

    var body: some View {
        ZStack(alignment: .top) {
            fakeMap

            VStack(spacing: 12) {
                searchBar

                Text("지도 터치 \(mapTapCount)회")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if listDetent == nil {
                Button("목록 보기") {
                    listDetent = .medium
                }
                .buttonStyle(.borderedProminent)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 20)
            }
        }
        .coordinateSpace(name: Self.coordinateSpace)
        .bottomSheet(detent: $listDetent) {
            popupList
        }
        .bottomSheet(item: $optionSheet, detent: $optionDetent) { sheet in
            optionContent(sheet)
        }
        // 시트를 끝까지 올려도 검색창은 보이게 한다.
        .bottomSheetTopInset(searchBarBottom + 20)
        .onChange(of: optionDetent) { _, detent in
            // 옵션 시트를 끌면 뒤의 목록 시트도 같은 높이로 따라간다.
            listDetent = detent
        }
    }
}

private extension MapSheetDemoView {
    var fakeMap: some View {
        // 격자 무늬로 지도를 흉내 내고, 누른 횟수를 세어 시트 밖 터치가 통과하는지 본다.
        Canvas { context, size in
            var path = Path()
            for x in stride(from: 0, through: size.width, by: 40) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: 40) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white.opacity(0.7)), lineWidth: 1)
        }
        .background(Color.green.opacity(0.25))
        .contentShape(Rectangle())
        .onTapGesture {
            mapTapCount += 1
        }
        .ignoresSafeArea()
    }

    var searchBar: some View {
        TextField("팝업 검색", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .background {
                GeometryReader { geometry in
                    let maxY = geometry.frame(in: .named(Self.coordinateSpace)).maxY
                    Color.clear
                        .onAppear {
                            searchBarBottom = maxY
                        }
                        .onChange(of: maxY) { _, newValue in
                            searchBarBottom = newValue
                        }
                }
            }
    }

    var popupList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("팝업 40개")
                    .font(.headline)

                Spacer()

                Button("지역") {
                    openOption(.region)
                }

                Button("정렬") {
                    openOption(.sort)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(1...40, id: \.self) { index in
                        Button {
                            openOption(.detail(index))
                        } label: {
                            HStack {
                                Text("팝업 \(index)")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    func optionContent(_ sheet: OptionSheet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(sheet.title)
                    .font(.headline)

                Spacer()

                Button {
                    optionSheet = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("닫기")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            switch sheet {
            case .region:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Self.regions, id: \.self) { region in
                            optionRow(region)
                        }
                    }
                }
            case .sort:
                ForEach(Self.sortOptions, id: \.self) { option in
                    optionRow(option)
                }
            case .detail(let index):
                Text("팝업 \(index) 미리보기. 시트를 연 채로 다른 팝업을 누르면 높이는 그대로 두고 내용만 바뀐다.")
                    .padding(.horizontal, 16)
            }
        }
    }

    func optionRow(_ title: String) -> some View {
        Button {
            optionSheet = nil
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func openOption(_ sheet: OptionSheet) {
        // 목록 시트가 숨어 있으면 중간 높이로 꺼내고, 옵션 시트는 목록 시트와 같은 높이로 연다.
        let detent = listDetent ?? .medium
        listDetent = detent
        optionDetent = detent
        optionSheet = sheet
    }
}
