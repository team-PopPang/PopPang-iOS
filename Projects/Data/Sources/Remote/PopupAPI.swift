import Core
import Foundation
import Moya

public enum PopupAPI {
    case getPopupList
    case getUpcomingPopupList
    case getInProgressPopupList
    case searchPopupList(searchText: String)
    case increaseViewCount(popupUuid: String)
    case getRandomPopupList

    case getPersonalPopupList(userUuid: String)
    case getPersonalUseerRecommendPopupList(userUuid: String)
    case getPersonalUpcomingPopupList(userUuid: String)
    case getPersonalFilteredPopupList(userUuid: String, region: String, district: String, homeSortStandard: String)
    case getPersonalSearchPopupList(userUuid: String, searchText: String)
    case getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    )
    case getPersonalRelatedPopupList(userUuid: String, popupUuid: String)
    case getPersonalRandomPopupList(userUuid: String)

    case getAlertPopupList(userUuid: String)
    case removeAlertPopup(userUuid: String, popupUuid: String)

    case addFavorite(userUuid: String, popupUuid: String)
    case removeFavorite(userUuid: String, popupUuid: String)
    case getFavoriteList(userUuid: String)

    case getRegionList
    case getPopularRecommendList
    case getPopularRecommendPopupList(userUuid: String, recommendId: Int)
}

extension PopupAPI: BaseAPI {
    public var path: String {
        switch self {
        case .getPopupList:
            return "/popup"
        case .getUpcomingPopupList:
            return "/popup/upcoming"
        case .getInProgressPopupList:
            return "/popup/inProgress"
        case .searchPopupList:
            return "/popup/search"
        case .increaseViewCount(let popupUuid):
            return "/popup/\(popupUuid)/view"
        case .getRandomPopupList:
            return "/popup/random"
        case .getPersonalPopupList(let userUuid):
            return "/users/\(userUuid)/popups"
        case .getPersonalUseerRecommendPopupList(let userUuid):
            return "/users/\(userUuid)/popups/recommend"
        case .getPersonalUpcomingPopupList(let userUuid):
            return "/users/\(userUuid)/popups/upcoming"
        case .getPersonalFilteredPopupList(let userUuid, _, _, _):
            return "/users/\(userUuid)/popups/filtered/home"
        case .getPersonalSearchPopupList(let userUuid, _):
            return "/users/\(userUuid)/popups/search"
        case .getPersonalMapFilteredPopupList(let userUuid, _, _, _, _, _):
            return "/users/\(userUuid)/popups/filtered/map"
        case .getPersonalRelatedPopupList(let userUuid, let popupUuid):
            return "/users/\(userUuid)/popups/\(popupUuid)/related"
        case .getPersonalRandomPopupList(let userUuid):
            return "/users/\(userUuid)/popups/random"
        case .getAlertPopupList(let userUuid):
            return "/users/\(userUuid)/alert/popups"
        case .removeAlertPopup(let userUuid, _):
            return "/users/\(userUuid)/alert"
        case .addFavorite, .removeFavorite:
            return "/favorite"
        case .getFavoriteList(let userUuid):
            return "/favorite/popup/\(userUuid)"
        case .getRegionList:
            return "/popup/regions/districts"
        case .getPopularRecommendList:
            return "recommend/featured"
        case .getPopularRecommendPopupList(let userUuid, let recommendId):
            return "/users/\(userUuid)/popups/recommendations/\(recommendId)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getPopupList,
             .getUpcomingPopupList,
             .getInProgressPopupList,
             .searchPopupList,
             .getRandomPopupList,
             .getPersonalPopupList,
             .getPersonalUseerRecommendPopupList,
             .getPersonalUpcomingPopupList,
             .getPersonalFilteredPopupList,
             .getPersonalSearchPopupList,
             .getPersonalMapFilteredPopupList,
             .getPersonalRelatedPopupList,
             .getPersonalRandomPopupList,
             .getAlertPopupList,
             .getFavoriteList,
             .getRegionList,
             .getPopularRecommendList,
             .getPopularRecommendPopupList:
            return .get
        case .increaseViewCount, .addFavorite:
            return .post
        case .removeAlertPopup, .removeFavorite:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .getPopupList,
             .getUpcomingPopupList,
             .getInProgressPopupList,
             .getRandomPopupList,
             .increaseViewCount,
             .getAlertPopupList,
             .getFavoriteList,
             .getRegionList,
             .getPopularRecommendList,
             .getPopularRecommendPopupList:
            return .requestPlain
        case .searchPopupList(let searchText):
            return .requestParameters(parameters: ["q": searchText], encoding: URLEncoding.queryString)
        case .getPersonalPopupList(let userUuid),
             .getPersonalUseerRecommendPopupList(let userUuid),
             .getPersonalUpcomingPopupList(let userUuid),
             .getPersonalRandomPopupList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid], encoding: URLEncoding.queryString)
        case .getPersonalFilteredPopupList(_, let region, let district, let homeSortStandard):
            return .requestParameters(
                parameters: [
                    "region": region,
                    "district": district,
                    "homeSortStandard": homeSortStandard,
                ],
                encoding: URLEncoding.queryString
            )
        case .getPersonalSearchPopupList(_, let searchText):
            return .requestParameters(parameters: ["q": searchText], encoding: URLEncoding.queryString)
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
        case .getPersonalRelatedPopupList(let userUuid, let popupUuid):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "popupUuid": popupUuid,
                ],
                encoding: URLEncoding.queryString
            )
        case .removeAlertPopup(_, let popupUuid):
            return .requestParameters(parameters: ["popupUuid": popupUuid], encoding: JSONEncoding.default)
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
