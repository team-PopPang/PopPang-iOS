import ComposableArchitecture
import Domain
import DSKit
import MapFeatureV2
import NMapsMap
import SwiftUI

@main
struct MapFeatureV2DemoApp: App {
    init() {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "NMFClientID") as? String,
           clientID.isEmpty == false,
           clientID.hasPrefix("$(") == false {
            NMFAuthManager.shared().ncpKeyId = clientID
        }
    }

    var body: some Scene {
        WindowGroup {
            DemoTabRoot()
        }
    }
}

/// 앱과 같은 탭바(`PopPangTabView`)를 목업으로 붙인다. 지도 탭만 실제 화면이고 나머지는 빈 화면이다.
private struct DemoTabRoot: View {
    enum Tab: String, CaseIterable {
        case home
        case calendar
        case map
        case favorite
        case profile

        var title: String {
            switch self {
            case .home: "홈"
            case .calendar: "캘린더"
            case .map: "팝팡지도"
            case .favorite: "팝팡"
            case .profile: "마이"
            }
        }
    }

    @State private var selection: Tab = .map
    @State private var store = Store(initialState: DemoMapRoot.State()) {
        DemoMapRoot()
    } withDependencies: {
        $0.mapFeatureClient = .demo
    }

    var body: some View {
        // 앱에서는 MainTab이 "상세보기" delegate를 받아 팝업 상세로 이동한다. 데모는 목업 상세 화면을 띄운다.
        NavigationStack {
            tabView
                .navigationDestination(item: Binding(
                    get: { store.detailPopup },
                    set: { if $0 == nil { store.send(.detailClosed) } }
                )) { popup in
                    VStack(spacing: 12) {
                        Text("팝업 상세 (목업)")
                            .font(.headline)
                        Text(popup.name)
                        Text(popup.popupUuid)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .navigationTitle("상세")
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var tabView: some View {
        PopPangTabView(
            selection: $selection,
            tabs: Tab.allCases,
            style: .classic,
            title: \.title,
            image: { tab, isSelected in
                DSKitResource.image(isSelected ? "\(tab.rawValue)_fill" : tab.rawValue)
            }
        ) { tab in
            if tab == .map {
                MapFeatureView(store: store.scope(state: \.map, action: \.map))
            } else {
                Text("\(tab.title) (목업)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// 데모 루트. 지도의 "상세보기" delegate를 받아 목업 상세를 연다(앱의 MainTab 역할).
@Reducer
private struct DemoMapRoot {
    @ObservableState
    struct State {
        var map = MapFeature.State()
        var detailPopup: Popup?
    }

    enum Action {
        case map(MapFeature.Action)
        case detailClosed
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Reduce { state, action in
            switch action {
            case .map(.delegate(.popupSelected(let popup))):
                state.detailPopup = popup
                return .none
            case .detailClosed:
                state.detailPopup = nil
                return .none
            case .map:
                return .none
            }
        }
    }
}

private extension MapFeatureClient {
    /// 가짜 서버. 서버가 거른 결과를 준다고 보고, 받은 조건과 상관없이 같은 목록을 준다.
    static let demo = MapFeatureClient(
        getRegionList: {
            [
                RegionList(region: "전체", districtList: ["전체"]),
                RegionList(region: "서울", districtList: ["전체", "성동구", "마포구", "강남구"]),
                RegionList(region: "부산", districtList: ["전체", "해운대구"]),
            ]
        },
        getRecommendList: {
            ["디저트", "캐릭터", "패션", "뷰티", "라이프", "전시"].enumerated().map {
                Recommend(id: $0.offset + 1, recommendName: $0.element)
            }
        },
        searchMapPopups: { _ in
            try await Task.sleep(for: .milliseconds(300))
            return MapPopupSearchResult(items: DemoPopups.all, totalCount: DemoPopups.all.count)
        },
        addFavorite: { _ in try await Task.sleep(for: .milliseconds(300)) },
        removeFavorite: { _ in try await Task.sleep(for: .milliseconds(300)) }
    )
}

private enum DemoPopups {
    static let all: [Popup] = [
        make("demo-1", "두바이쫀득쿠키", "디저트", 37.5446, 127.0557),
        make("demo-2", "가을 캐릭터 마켓", "캐릭터", 37.5478, 127.0601),
        make("demo-3", "모락절미 쫀득절미 팝업", "디저트", 37.5420, 127.0530),
        make("demo-4", "두쫀쿠", "라이프", 37.5401, 127.0589),
        make("demo-5", "성수 패션 위크", "패션", 37.5462, 127.0498),
    ]

    static func make(_ id: String, _ name: String, _ category: String, _ lat: Double, _ lng: Double) -> Popup {
        let today = Calendar.current.startOfDay(for: Date())
        return Popup(
            popupUuid: id,
            name: name,
            startDate: today.addingTimeInterval(-86_400 * 3),
            endDate: today.addingTimeInterval(86_400 * 5),
            openTime: "10:00",
            closeTime: "20:00",
            address: "서울 성동구 성수동",
            roadAddress: "서울 성동구 성수동",
            region: "서울",
            latitude: lat,
            longitude: lng,
            instaPostId: nil,
            instaPostUrl: nil,
            captionSummary: "데모 팝업입니다.",
            imageUrlList: [],
            mediaType: .image,
            favoriteCount: 12,
            viewCount: 84,
            isFavorited: false,
            recommendList: [category]
        )
    }
}
