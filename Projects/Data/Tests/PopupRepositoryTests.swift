import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct PopupRepositoryTests {
    @Test("회원 팝업 검색은 V2 경로에 사용자 UUID 없이 검색어를 q로 보내고 Access Token을 쓴다")
    func searchRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .search(q: "성수")).urlRequest()

        #expect(request.url?.path == "/api/v2/user/popups/search")
        #expect(URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems == [URLQueryItem(name: "q", value: "성수")])
        #expect(request.httpMethod == "GET")
        #expect(V2PopupAPI.search(q: "성수").resolvedAuthorization == .access)
    }

    @Test("회원 팝업 검색은 감싸지 않은 팝업 배열을 읽고 Access Token을 보낸다")
    func searchReadsPopupArray() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))

        let popups = try await context.repository.getPersonalSearchPopupList(searchText: "성수")

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(popups.first?.isFavorited == true)
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("명세상 null일 수 있는 도로명 주소·미디어 종류·추천 카테고리가 null이어도 목록을 읽는다")
    func searchReadsNullableFields() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))

        let popup = try #require(try await context.repository.getPersonalSearchPopupList(searchText: "성수").first)

        #expect(popup.roadAddress == "서울 성동구")
        #expect(popup.mediaType == .image)
        #expect(popup.recommendList.isEmpty)
    }

    @Test("검색이 서버 오류로 실패하면 화면이 안내할 PopupError로 바꾼다")
    func searchMapsServerErrorToPopupError() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getPersonalSearchPopupList(searchText: "성수")
        }
    }

    @Test("다시 로그인해야 하는 실패는 바꾸지 않고 그대로 던진다")
    func searchPassesLoginRequiredThrough() async {
        let context = PopupRepositoryContext(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.getPersonalSearchPopupList(searchText: "성수")
        }
    }

    @Test("도로명 주소가 빈 문자열이어도 일반 주소를 쓴다")
    func searchUsesAddressWhenRoadAddressIsEmpty() async throws {
        let popupJSON = PopupFixture.popup.replacingOccurrences(of: "\"roadAddress\":null", with: "\"roadAddress\":\"\"")
        let context = PopupRepositoryContext(response: (200, "[\(popupJSON)]"))

        let popup = try #require(try await context.repository.getPersonalSearchPopupList(searchText: "성수").first)

        #expect(popup.roadAddress == "서울 성동구")
    }

    @Test("검색 결과가 없으면 빈 배열을 돌려준다")
    func searchReturnsEmptyArray() async throws {
        let context = PopupRepositoryContext(response: (200, "[]"))

        #expect(try await context.repository.getPersonalSearchPopupList(searchText: "없는팝업").isEmpty)
    }

    // MARK: - S01 조회 기록·관련 팝업 (V2)

    @Test("S01 조회 기록은 V2 경로에 POST로 본문 없이 보내고 Access Token을 쓴다")
    func s01ViewRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .view(popupUuid: "popup-1")).urlRequest()

        #expect(request.url?.path == "/api/v2/popup/popup-1/view")
        #expect(request.url?.query == nil)
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == nil)
        #expect(V2PopupAPI.view(popupUuid: "popup-1").resolvedAuthorization == .access)
    }

    @Test("S01 조회 기록이 성공하면 Access Token을 담아 한 번 보낸다")
    func s01ViewSendsAccessToken() async throws {
        let context = PopupRepositoryContext(response: (200, ""))

        try await context.repository.increaseViewCount(popupUuid: "popup-1")

        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
        #expect(context.recorder.httpMethods == ["POST"])
    }

    @Test("S01 조회 기록이 서버 오류로 실패하면 PopupError로 바꾼다")
    func s01ViewMapsServerErrorToPopupError() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":9999,"message":"error","data":null}"#))

        await #expect(throws: PopupError.failed) {
            try await context.repository.increaseViewCount(popupUuid: "popup-1")
        }
    }

    @Test("S01 관련 팝업은 V2 경로에 사용자 UUID 없이 GET으로 보내고 Access Token을 쓴다")
    func s01RelatedRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .related(popupUuid: "popup-1")).urlRequest()

        #expect(request.url?.path == "/api/v2/user/popups/popup-1/related")
        #expect(request.url?.query == nil)
        #expect(request.httpMethod == "GET")
        #expect(V2PopupAPI.related(popupUuid: "popup-1").resolvedAuthorization == .access)
    }

    @Test("S01 관련 팝업은 감싸지 않은 팝업 배열을 읽는다")
    func s01RelatedReadsPopupArray() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))

        let popups = try await context.repository.getRelatedPopupList(popupUuid: "popup-0")

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("S01 관련 팝업이 서버 오류로 실패하면 PopupError로 바꾼다")
    func s01RelatedMapsServerErrorToPopupError() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":9999,"message":"error","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getRelatedPopupList(popupUuid: "popup-0")
        }
    }

    // MARK: - S03 상세 단건 조회 (V2)

    @Test("S03 단건 조회는 V2 경로에 GET으로 보내고 Access Token을 쓴다")
    func s03DetailRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .detail(popupUuid: "popup-1")).urlRequest()

        #expect(request.url?.path == "/api/v2/user/popups/popup-1")
        #expect(request.url?.query == nil)
        #expect(request.httpMethod == "GET")
        #expect(V2PopupAPI.detail(popupUuid: "popup-1").resolvedAuthorization == .access)
    }

    @Test("S03 단건 조회는 감싸지 않은 팝업 하나를 하트 상태와 함께 PopupDetail로 읽는다")
    func s03DetailReadsPopupDetail() async throws {
        let context = PopupRepositoryContext(response: (200, PopupFixture.popup))

        let detail = try await context.repository.getPopupDetail(popupUuid: "popup-1")

        #expect(detail.popupUuid == "popup-1")
        #expect(detail.name == "성수 팝업")
        #expect(detail.isFavorited == true)
        #expect(detail.favoriteCount == 12)
        #expect(detail.viewCount == 34)
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("S03 단건 조회는 null일 수 있는 도로명 주소·미디어 종류·추천 카테고리를 목록과 같은 기준으로 바꾼다")
    func s03DetailReadsNullableFields() async throws {
        let context = PopupRepositoryContext(response: (200, PopupFixture.popup))

        let detail = try await context.repository.getPopupDetail(popupUuid: "popup-1")

        #expect(detail.roadAddress == "서울 성동구")
        #expect(detail.mediaType == .image)
        #expect(detail.recommendList.isEmpty)
    }

    @Test("S03 없는 팝업(404 4301)은 PopupError.notFound로 바꾼다")
    func s03DetailMapsNotFound() async {
        let context = PopupRepositoryContext(response: (404, #"{"success":false,"code":4301,"message":"error","data":null}"#))

        await #expect(throws: PopupError.notFound) {
            _ = try await context.repository.getPopupDetail(popupUuid: "popup-1")
        }
    }

    @Test("S03 그 밖의 실패는 PopupError.failed로 바꾼다", arguments: [
        (404, #"{"success":false,"code":9999,"message":"error","data":null}"#),
        (500, #"{"success":false,"code":9999,"message":"error","data":null}"#),
    ])
    func s03DetailMapsOtherFailures(response: (Int, String)) async {
        let context = PopupRepositoryContext(response: response)

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getPopupDetail(popupUuid: "popup-1")
        }
    }

    @Test("S03 없는 팝업(404 4301) 구분은 단건 조회에만 적용하고 관련 팝업은 지금처럼 failed로 바꾼다")
    func s03NotFoundOnlyForDetail() async {
        let context = PopupRepositoryContext(response: (404, #"{"success":false,"code":4301,"message":"error","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getRelatedPopupList(popupUuid: "popup-1")
        }
    }

    @Test("S03 단건 조회도 다시 로그인해야 하는 실패는 그대로 던진다")
    func s03DetailPassesLoginRequiredThrough() async {
        let context = PopupRepositoryContext(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.getPopupDetail(popupUuid: "popup-1")
        }
    }

    // MARK: - 달력 필터 팝업·지역 목록 (V2)

    @Test("필터 팝업은 V2 경로에 사용자 UUID 없이 지역·구·정렬을 query로 보내고 Access Token을 쓴다")
    func filteredRequestMatchesV2Contract() throws {
        let target = V2PopupAPI.filteredHome(region: "서울", district: "성동구", homeSortStandard: "NEWEST")
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: target).urlRequest()
        let queryItems = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []

        #expect(request.url?.path == "/api/v2/user/popups/filtered/home")
        #expect(Set(queryItems) == [
            URLQueryItem(name: "region", value: "서울"),
            URLQueryItem(name: "district", value: "성동구"),
            URLQueryItem(name: "homeSortStandard", value: "NEWEST"),
        ])
        #expect(request.httpMethod == "GET")
        #expect(target.resolvedAuthorization == .access)
    }

    @Test("필터 팝업은 감싸지 않은 팝업 배열을 읽고 Access Token을 보낸다")
    func filteredReadsPopupArray() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))

        let popups = try await context.repository.getFilteredPopupList(region: "전체", district: "전체", homeSortStandard: "NEWEST")

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("필터 팝업이 서버 오류로 실패하면 PopupError로 바꾼다")
    func filteredMapsServerErrorToPopupError() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getFilteredPopupList(region: "전체", district: "전체", homeSortStandard: "NEWEST")
        }
    }

    // MARK: - 지도 목록·카테고리 (V2)

    @Test("지도 목록은 V2 경로에 지역·구·위치·정렬을 query로 보내고 Access Token을 쓴다")
    func mapRequestMatchesV2Contract() throws {
        let target = V2PopupAPI.filteredMap(region: "서울", district: "전체", latitude: 37.5, longitude: 127.05, mapSortStandard: "CLOSEST")
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: target).urlRequest()
        let queryItems = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []

        #expect(request.url?.path == "/api/v2/user/popups/filtered/map")
        #expect(Set(queryItems) == [
            URLQueryItem(name: "region", value: "서울"),
            URLQueryItem(name: "district", value: "전체"),
            URLQueryItem(name: "latitude", value: "37.5"),
            URLQueryItem(name: "longitude", value: "127.05"),
            URLQueryItem(name: "mapSortStandard", value: "CLOSEST"),
        ])
        #expect(target.resolvedAuthorization == .access)
    }

    @Test("지도 목록은 위치를 모르면 위도·경도를 보내지 않는다")
    func mapRequestOmitsUnknownLocation() throws {
        let target = V2PopupAPI.filteredMap(region: "전체", district: "전체", latitude: nil, longitude: nil, mapSortStandard: "NEWEST")
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: target).urlRequest()
        let names = Set((URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []).map(\.name))

        #expect(names == ["region", "district", "mapSortStandard"])
    }

    @Test("지도 목록과 카테고리 목록은 감싸지 않은 배열을 읽고, 실패하면 PopupError로 바꾼다")
    func mapAndRecommendRead() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))
        let popups = try await context.repository.getMapPopupList(region: "전체", district: "전체", latitude: nil, longitude: nil, mapSortStandard: "NEWEST")
        #expect(popups.map(\.popupUuid) == ["popup-1"])

        let recommendContext = PopupRepositoryContext(response: (200, #"[{"id":1,"recommendName":"디저트"}]"#))
        #expect(try await recommendContext.repository.getRecommendList() == [Recommend(id: 1, recommendName: "디저트")])
        #expect(try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .recommendList).urlRequest().url?.path == "/api/v2/recommend")

        let failing = PopupRepositoryContext(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))
        await #expect(throws: PopupError.failed) {
            _ = try await failing.repository.getRecommendList()
        }
    }

    // MARK: - 홈 랜덤·오픈 예정 (V2)

    @Test("랜덤·오픈 예정은 V2 경로에 사용자 UUID와 query 없이 GET으로 보내고 Access Token을 쓴다")
    func homeRequestsMatchV2Contract() throws {
        let random = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .random).urlRequest()
        let upcoming = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .upcoming).urlRequest()

        #expect(random.url?.path == "/api/v2/user/popups/random")
        #expect(upcoming.url?.path == "/api/v2/user/popups/upcoming")
        #expect(random.url?.query == nil)
        #expect(upcoming.url?.query == nil)
        #expect(random.httpMethod == "GET")
        #expect(upcoming.httpMethod == "GET")
        #expect(V2PopupAPI.random.resolvedAuthorization == .access)
        #expect(V2PopupAPI.upcoming.resolvedAuthorization == .access)
    }

    @Test("랜덤·오픈 예정은 감싸지 않은 팝업 배열을 읽고 Access Token을 보낸다")
    func homeListsReadPopupArray() async throws {
        let context = PopupRepositoryContext(response: (200, "[\(PopupFixture.popup)]"))

        #expect(try await context.repository.getUserRandomPopupList().map(\.popupUuid) == ["popup-1"])
        #expect(try await context.repository.getUserUpcomingPopupList().map(\.popupUuid) == ["popup-1"])
        #expect(context.recorder.authorizationHeaders == ["Bearer access", "Bearer access"])
    }

    @Test("랜덤·오픈 예정이 서버 오류로 실패하면 PopupError로 바꾼다")
    func homeListsMapServerErrorToPopupError() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getUserRandomPopupList()
        }
        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getUserUpcomingPopupList()
        }
    }

    @Test("지역 목록은 V2 경로에 GET으로 보내고 Access Token을 쓴다")
    func regionListRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .regionList).urlRequest()

        #expect(request.url?.path == "/api/v2/popup/regions/districts")
        #expect(request.httpMethod == "GET")
        #expect(V2PopupAPI.regionList.resolvedAuthorization == .access)
    }

    @Test("지역 목록은 감싸지 않은 지역 배열을 읽는다")
    func regionListReadsArray() async throws {
        let context = PopupRepositoryContext(response: (200, #"[{"region":"서울","districtList":["전체","성동구"]}]"#))

        let regions = try await context.repository.getRegionList()

        #expect(regions == [RegionList(region: "서울", districtList: ["전체", "성동구"])])
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("지역 목록이 실패하면 홈·지도가 V1 때처럼 문구를 보여 주도록 받은 네트워크 오류를 그대로 던진다")
    func regionListPassesNetworkErrorThrough() async {
        let context = PopupRepositoryContext(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))

        await #expect(throws: NetworkError.self) {
            _ = try await context.repository.getRegionList()
        }
    }
}

// MARK: - 테스트 도구

/// 팝업·찜 Repository 테스트가 함께 쓰는 도구
enum PopupFixture {
    static let popup = """
    {"popupUuid":"popup-1","name":"성수 팝업","startDate":"26.05.01","endDate":"26.05.31","openTime":"10:00","closeTime":"20:00","address":"서울 성동구","roadAddress":null,"region":"서울","latitude":37.544,"longitude":127.055,"instaPostId":null,"instaPostUrl":null,"captionSummary":"요약","imageUrlList":[],"mediaType":null,"favoriteCount":12,"viewCount":34,"isFavorited":true,"recommendList":null}
    """
}

/// 메모리에 값을 두는 저장 수단
final class PopupTestStore: Storing, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Any] = [:]

    func value<T>(forKey key: String) -> T? {
        lock.withLock { values[key] as? T }
    }

    func set<T>(_ value: T, forKey key: String) throws {
        lock.withLock { values[key] = value }
    }

    func removeValue(forKey key: String) {
        lock.withLock { _ = values.removeValue(forKey: key) }
    }
}

/// 보낸 요청을 기록한다. `URLRequest`가 없는 요청도 `nil`로 남겨 보낸 횟수를 그대로 센다.
final class RequestRecorder: PluginType, @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [URLRequest?] = []

    var authorizationHeaders: [String?] {
        lock.withLock { requests.map { $0?.value(forHTTPHeaderField: "Authorization") } }
    }

    var httpMethods: [String?] {
        lock.withLock { requests.map { $0?.httpMethod } }
    }

    func willSend(_ request: RequestType, target: TargetType) {
        lock.withLock { requests.append(request.request) }
    }
}

struct PopupRepositoryContext {
    let recorder: RequestRecorder
    let repository: PopupRepositoryImpl

    init(response: (Int, String)) {
        let storage = AuthTokenStorage(store: PopupTestStore())
        try? storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: AccessTokenRefresher(storage: storage) { _ in
                throw NetworkError.invalidStatusCode(401, message: #"{"success":false,"code":5007,"message":"error","data":null}"#)
            }
        )
        let networkProvider = NetworkProvider(stubClosure: MoyaProvider.immediatelyStub, authentication: authentication)
        let recorder = RequestRecorder()

        func makeProvider<T: TargetType>() -> MoyaProvider<T> {
            networkProvider.makeProvider(
                endpointClosure: { target in
                    Endpoint(
                        url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                        sampleResponseClosure: { .networkResponse(response.0, Data(response.1.utf8)) },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers
                    )
                },
                plugins: [recorder]
            )
        }

        self.recorder = recorder
        self.repository = PopupRepositoryImpl(
            makeV2Provider: { makeProvider() },
            makeV2FavoriteProvider: { makeProvider() }
        )
    }
}
