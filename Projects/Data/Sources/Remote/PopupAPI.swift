import Core
import Foundation
import Moya

/// V1 회원 팝업 API
///
/// 앱에 연결된 화면은 모두 V2(`/api/v2/mobile`)로 옮겼다. 앱에 연결되지 않은 옛 모듈 `MapFeatureV1`과 `CalendarFeature`가 쓰는 case만 남아서, 출시 앱은 이 API를 호출하지 않는다.
public enum PopupAPI {
    case getPersonalFilteredPopupList(userUuid: String, region: String, district: String, homeSortStandard: String)
    case getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    )

    case addFavorite(userUuid: String, popupUuid: String)
    case removeFavorite(userUuid: String, popupUuid: String)

    case getPopularRecommendList
    case getPopularRecommendPopupList(userUuid: String, recommendId: Int)
}

extension PopupAPI: BaseAPI {
    public var path: String {
        switch self {
        case .getPersonalFilteredPopupList(let userUuid, _, _, _):
            return "/users/\(userUuid)/popups/filtered/home"
        case .getPersonalMapFilteredPopupList(let userUuid, _, _, _, _, _):
            return "/users/\(userUuid)/popups/filtered/map"
        case .addFavorite, .removeFavorite:
            return "/favorite"
        case .getPopularRecommendList:
            return "recommend/featured"
        case .getPopularRecommendPopupList(let userUuid, let recommendId):
            return "/users/\(userUuid)/popups/recommendations/\(recommendId)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getPersonalFilteredPopupList,
             .getPersonalMapFilteredPopupList,
             .getPopularRecommendList,
             .getPopularRecommendPopupList:
            return .get
        case .addFavorite:
            return .post
        case .removeFavorite:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .getPopularRecommendList,
             .getPopularRecommendPopupList:
            return .requestPlain
        case .getPersonalFilteredPopupList(_, let region, let district, let homeSortStandard):
            return .requestParameters(
                parameters: [
                    "region": region,
                    "district": district,
                    "homeSortStandard": homeSortStandard,
                ],
                encoding: URLEncoding.queryString
            )
        case .getPersonalMapFilteredPopupList(_, let region, let district, let latitude, let longitude, let mapSortStandard):
            var params: [String: Any] = [
                "region": region,
                "district": district,
                "mapSortStandard": mapSortStandard,
            ]
            if let latitude, let longitude {
                params["latitude"] = latitude
                params["longitude"] = longitude
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .addFavorite(let userUuid, let popupUuid), .removeFavorite(let userUuid, let popupUuid):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "popupUuid": popupUuid,
                ],
                encoding: JSONEncoding.default
            )
        }
    }
}
