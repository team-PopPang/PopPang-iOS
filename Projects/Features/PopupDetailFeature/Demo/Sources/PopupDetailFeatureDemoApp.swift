import ComposableArchitecture
import Domain
import Foundation
import PopupDetailFeature
import SwiftUI

/// `-demoDetail notFound`면 없는 팝업 화면을 띄운다. `-demoDetail failed`면 첫 요청이 실패하고
/// 로딩을 유지한 채 자동으로 다시 요청해 내용을 보여 준다. 인자가 없으면 1초 로딩 뒤 내용을 보여 준다.
///
/// 실제 앱처럼 `NavigationStack`에서 상세를 push로 연다. 그래야 상세의 뒤로 가기 버튼(툴바)이 보인다.
/// 실행하면 상세가 바로 열린 상태로 시작하고, 뒤로 가면 시작 화면에서 다시 열 수 있다.
/// 관련 팝업을 누르면 그 상세가 push된다 (데모 데이터라 같은 팝업이 다시 열린다).
@main
struct PopupDetailFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PopupDetailDemoRootView()
        }
    }
}

/// 데모 화면 이동 경로
private enum PopupDetailDemoRoute: Hashable {
    case detail(popupUuid: String)
}

private struct PopupDetailDemoRootView: View {
    @State private var path: [PopupDetailDemoRoute] = [.detail(popupUuid: PopupDetail.popupDetailDemo.popupUuid)]
    /// 실행 인자는 처음에 한 번만 읽는다.
    private let mode = DemoDetailMode.fromLaunchArguments()

    var body: some View {
        NavigationStack(path: $path) {
            Button("팝업 상세 열기") {
                path.append(.detail(popupUuid: PopupDetail.popupDetailDemo.popupUuid))
            }
            .navigationTitle("PopupDetail 데모")
            .navigationDestination(for: PopupDetailDemoRoute.self) { route in
                switch route {
                case .detail(let popupUuid):
                    PopupDetailDemoScreen(popupUuid: popupUuid, mode: mode) { relatedUuid in
                        path.append(.detail(popupUuid: relatedUuid))
                    }
                }
            }
        }
    }
}

/// 상세 하나. Store와 가짜 client를 `@State`로 한 번만 만들어, 상위 화면이 다시 그려져도 상세 상태가 유지된다.
private struct PopupDetailDemoScreen: View {
    @State private var store: StoreOf<PopupDetailFeature>
    private let onSelectRelatedPopup: (String) -> Void

    init(popupUuid: String, mode: DemoDetailMode, onSelectRelatedPopup: @escaping (String) -> Void) {
        _store = State(initialValue: Store(initialState: PopupDetailFeature.State(popupUuid: popupUuid)) {
            PopupDetailFeature()
        } withDependencies: {
            $0.popupDetailClient = .demo(mode: mode)
        })
        self.onSelectRelatedPopup = onSelectRelatedPopup
    }

    var body: some View {
        PopupDetailFeatureView(store: store, onSelectRelatedPopup: onSelectRelatedPopup)
    }
}

private extension PopupDetailClient {
    /// 데모용 가짜 client. 상세를 열 때마다 하나씩 만들어 실패 모드가 그 화면의 첫 요청부터 적용된다.
    static func demo(mode: DemoDetailMode) -> Self {
        let attempts = DemoAttemptCounter()
        return PopupDetailClient(
            getPopupDetail: { _ in
                try await Task.sleep(for: .seconds(1))
                let attempt = attempts.next()
                switch mode {
                case .notFound:
                    throw PopupError.notFound
                case .failed where attempt == 1:
                    throw PopupError.failed
                case .failed, .success:
                    return .popupDetailDemo
                }
            },
            increaseViewCount: { _ in },
            getRelatedPopupList: { _ in
                [.relatedPopupDetailDemo]
            },
            addFavorite: { _ in },
            removeFavorite: { _ in },
            deactivatePopup: { _ in }
        )
    }
}

private enum DemoDetailMode {
    case success
    case notFound
    case failed

    static func fromLaunchArguments() -> Self {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-demoDetail"), arguments.indices.contains(index + 1) else {
            return .success
        }
        switch arguments[index + 1] {
        case "notFound": return .notFound
        case "failed": return .failed
        default: return .success
        }
    }
}

/// 데모의 다시 시도 확인용. 몇 번째 요청인지 센다.
private final class DemoAttemptCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.withLock {
            count += 1
            return count
        }
    }
}

private extension PopupDetail {
    static let popupDetailDemo = PopupDetail(
        popupUuid: "popup-detail-demo",
        name: "더현대 서울 x 도시크랩",
        startDate: .popupDetailDemoDate(year: 2026, month: 7, day: 24),
        endDate: .popupDetailDemoDate(year: 2026, month: 7, day: 31),
        openTime: "00:00",
        closeTime: "00:00",
        address: "서울 영등포구 여의도동",
        roadAddress: "서울 영등포구 여의대로 108 지하2층",
        region: "서울",
        latitude: 37.5259,
        longitude: 126.9284,
        instaPostId: nil,
        instaPostUrl: "https://www.instagram.com/",
        captionSummary: """
        🦀 더현대 서울 x 도시크랩 팝업
        📍 더현대 서울
        📅 7.24 ~ 7.31
        🕒 운영시간 미기재

        푸드 팝업으로 진행되는 행사입니다.
        게살 내장볶음밥과 칠리새우 세트 메뉴가 소개되어 있어요.
        넛츠그린 스파클링 음료도 함께 만나볼 수 있습니다.
        만원대 구성으로 가볍게 즐기기 좋습니다.
        짧은 기간 동안 열리는 만큼 현장 분위기도 빠르게 지나갈 것 같아요.
        맛있는 메뉴를 중심으로 구성된 캐주얼한 팝업입니다.
        """,
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_2.jpg",
        ],
        mediaType: .carousel,
        favoriteCount: 52,
        viewCount: 244,
        isFavorited: false,
        recommendList: ["디저트"]
    )
}

private extension Popup {
    static let relatedPopupDetailDemo = Popup(
        popupUuid: "related-popup-detail-demo",
        name: "여의도 디저트 팝업",
        startDate: .popupDetailDemoDate(year: 2026, month: 8, day: 1),
        endDate: .popupDetailDemoDate(year: 2026, month: 8, day: 7),
        openTime: "10:30",
        closeTime: "20:00",
        address: "서울 영등포구 여의도동",
        roadAddress: "서울 영등포구 여의대로 108",
        region: "서울",
        latitude: 37.5259,
        longitude: 126.9284,
        instaPostId: nil,
        instaPostUrl: nil,
        captionSummary: "팝업 상세 화면의 추천 카드 확인을 위한 데모입니다.",
        imageUrlList: [
            "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
        ],
        mediaType: .image,
        favoriteCount: 18,
        viewCount: 96,
        isFavorited: true,
        recommendList: ["디저트"]
    )
}

private extension Date {
    static func popupDetailDemoDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        ) ?? .distantPast
    }
}
