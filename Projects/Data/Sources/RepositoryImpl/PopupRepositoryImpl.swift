import Core
import Domain
import Foundation
import Moya

public final class PopupRepositoryImpl: PopupRepositoryProtocol {
    private let makeV2Provider: () -> MoyaProvider<V2PopupAPI>
    private let makeV2FavoriteProvider: () -> MoyaProvider<V2FavoriteAPI>

    public init(
        makeV2Provider: @escaping () -> MoyaProvider<V2PopupAPI> = { NetworkProvider.shared.makeProvider() },
        makeV2FavoriteProvider: @escaping () -> MoyaProvider<V2FavoriteAPI> = { NetworkProvider.shared.makeProvider() }
    ) {
        self.makeV2Provider = makeV2Provider
        self.makeV2FavoriteProvider = makeV2FavoriteProvider
    }

    public func getPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getUpcomingPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getUpcomingPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getInProgressPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getInProgressPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getFavoriteList() async throws -> [Popup] {
        // 명세 FAV-04: 검색과 달리 성공 응답이 `APIResponse`로 감싸져 있다.
        try await popupRequest {
            try await makeV2FavoriteProvider().asyncRequest(.list, decodeDataTo: [PopupDTO].self)
                .map { $0.toEntity() }
        }
    }

    public func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.searchPopupList(searchText: searchText), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getRandomPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getRandomPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPersonalPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUseerRecommendPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUpcomingPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                homeSortStandard: homeSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalSearchPopupList(searchText: String) async throws -> [Popup] {
        // 명세 UPOP-11: 성공 응답은 `APIResponse`로 감싸지 않은 팝업 배열이다(`wrapper NONE → NONE`).
        try await popupRequest {
            try await makeV2Provider().asyncRequest(.search(q: searchText), decodeTo: [PopupDTO].self)
                .map { $0.toEntity() }
        }
    }

    public func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalMapFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                latitude: latitude,
                longitude: longitude,
                mapSortStandard: mapSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRelatedPopupList(userUuid: userUuid, popupUuid: popupUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRandomPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getAlertPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeAlertPopup(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func increaseViewCount(popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.increaseViewCount(popupUuid: popupUuid))
    }

    public func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.addFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func addFavorite(popupUuid: String) async throws {
        // 명세 FAV-01: 이미 찜한 팝업은 409 4101이다. 성공으로 보지 않고 다른 실패와 같이 PopupError로 바꾼다.
        try await popupRequest {
            try await makeV2FavoriteProvider().asyncRequestVoid(.add(popupUuid: popupUuid))
        }
    }

    public func removeFavorite(popupUuid: String) async throws {
        // 명세 FAV-02: 찜하지 않은 팝업은 404 4102다. 성공으로 보지 않고 다른 실패와 같이 PopupError로 바꾼다.
        try await popupRequest {
            try await makeV2FavoriteProvider().asyncRequestVoid(.remove(popupUuid: popupUuid))
        }
    }

    public func getRegionList() async throws -> [RegionList] {
        try await popupProvider.asyncRequest(.getRegionList, decodeTo: [RegionListDTO].self).map { $0.toEntity() }
    }

    public func getPopularRecommendList() async throws -> [Recommend] {
        try await popupProvider.asyncRequest(.getPopularRecommendList, decodeTo: [RecommendListDTO].self).map { $0.toModel() }
    }

    public func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPopularRecommendPopupList(userUuid: userUuid, recommendId: recommendId),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    private var popupProvider: MoyaProvider<PopupAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

private extension PopupRepositoryImpl {
    /// V2 팝업·찜 요청의 실패를 화면이 안내할 `PopupError`로 바꾼다. 다시 로그인해야 하는 실패는 그대로 던진다.
    func popupRequest<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch let error as AuthSessionError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // 화면에는 PopupError로 안내하지만 원인을 찾을 수 있게 남긴다.
            // 출시 빌드에도 찍히므로 서버 응답 본문이나 검색어가 담긴 URL은 남기지 않고 코드와 오류 종류만 남긴다.
            Logger.e("팝업 요청 실패: \(Self.logDescription(of: error))")
            throw PopupError.failed
        }
    }

    static func logDescription(of error: Error) -> String {
        guard let error = error as? NetworkError else {
            return String(describing: type(of: error))
        }
        return "HTTP \(error.statusCode), code \(error.serverErrorCode.map(String.init) ?? "없음")"
    }
}
