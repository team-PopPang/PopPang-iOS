import Core
import Domain
import Foundation
import Moya

public enum AdminAPI {
    case deactivatePopup(userUuid: String, popupUuid: String)
}

extension AdminAPI: BaseAPI {
    public var path: String {
        switch self {
        case .deactivatePopup(let userUuid, let popupUuid):
            return "/admin/user/\(userUuid)/popup/\(popupUuid)/deactivate"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .deactivatePopup:
            return .patch
        }
    }

    public var task: Task {
        .requestPlain
    }
}

public enum AppleAuthAPI {
    case loginWithEmail(authCode: String, email: String)
    case login(authCode: String)
    case signup(userDto: UserDTO)
}

extension AppleAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .loginWithEmail, .login:
            return "/auth/apple/mobile/login"
        case .signup:
            return "/auth/apple/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .loginWithEmail(let authCode, let email):
            return .requestJSONEncodable([
                "auth_code": authCode,
                "email": email,
            ])
        case .login(let authCode):
            return .requestJSONEncodable(["auth_code": authCode])
        case .signup(let userDto):
            return .requestJSONEncodable(userDto)
        }
    }
}

public enum GoogleAuthAPI {
    case login(idToken: String)
    case signup(userDTO: UserDTO)
}

extension GoogleAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .login:
            return "/auth/google/mobile/login"
        case .signup:
            return "/auth/google/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .login(let idToken):
            return .requestJSONEncodable(["id_token": idToken])
        case .signup(let userDTO):
            return .requestJSONEncodable(userDTO)
        }
    }
}

public enum KakaoAuthAPI {
    case login(accessToken: String)
    case signup(userDTO: UserDTO)
}

extension KakaoAuthAPI: BaseAPI {
    public var path: String {
        switch self {
        case .login:
            return "/auth/kakao/mobile/login"
        case .signup:
            return "/auth/kakao/signup"
        }
    }

    public var method: Moya.Method {
        .post
    }

    public var task: Task {
        switch self {
        case .login(let accessToken):
            return .requestJSONEncodable(["access_token": accessToken])
        case .signup(let userDTO):
            return .requestJSONEncodable(userDTO)
        }
    }
}

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

public enum UserAPI {
    case checkNickname(nickname: String)
    case updateNickname(userUuid: String, newNickname: String)
    case autoLogin(userUuid: String)
    case getRecommendList
    case hardDeleteUser(userUuid: String)
    case getAlertKeywordList(userUuid: String)
    case addAlertKeyword(userUuid: String, newAlertKeyword: String)
    case removeAlertKeyword(userUuid: String, deleteAlertKeyword: String)
    case alertStatus(userUuid: String, isAlerted: Bool)
    case checkFcmToken(userUuid: String, fcmToken: String)
    case updateFcmToken(userUuid: String, newFcmToken: String)
}

extension UserAPI: BaseAPI {
    public var path: String {
        switch self {
        case .checkNickname:
            return "/user/nickname/duplicated"
        case .updateNickname(let userUuid, _):
            return "/user/\(userUuid)"
        case .autoLogin:
            return "/auth/autoLogin"
        case .getRecommendList:
            return "/recommend"
        case .hardDeleteUser(let userUuid):
            return "/user/\(userUuid)/hard-delete"
        case .getAlertKeywordList, .addAlertKeyword, .removeAlertKeyword:
            return "/alert-keyword"
        case .alertStatus(let userUuid, _):
            return "/user/\(userUuid)/alert-status"
        case .checkFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/duplicate-check"
        case .updateFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/update"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .checkNickname, .getRecommendList, .getAlertKeywordList, .checkFcmToken:
            return .get
        case .autoLogin, .addAlertKeyword:
            return .post
        case .updateNickname, .alertStatus:
            return .patch
        case .updateFcmToken:
            return .put
        case .hardDeleteUser, .removeAlertKeyword:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname], encoding: URLEncoding.queryString)
        case .updateNickname(_, let newNickname):
            return .requestParameters(parameters: ["nickname": newNickname], encoding: JSONEncoding.default)
        case .autoLogin(let userUuid):
            return .requestJSONEncodable(["userUuid": userUuid])
        case .getRecommendList, .hardDeleteUser:
            return .requestPlain
        case .getAlertKeywordList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid], encoding: URLEncoding.queryString)
        case .addAlertKeyword(let userUuid, let newAlertKeyword):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "newAlertKeyword": newAlertKeyword,
                ],
                encoding: JSONEncoding.default
            )
        case .removeAlertKeyword(let userUuid, let deleteAlertKeyword):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "deleteAlertKeyword": deleteAlertKeyword,
                ],
                encoding: JSONEncoding.default
            )
        case .alertStatus(_, let isAlerted):
            return .requestParameters(parameters: ["isAlerted": isAlerted], encoding: JSONEncoding.default)
        case .checkFcmToken(_, let fcmToken):
            return .requestParameters(parameters: ["fcmToken": fcmToken], encoding: URLEncoding.queryString)
        case .updateFcmToken(_, let newFcmToken):
            return .requestParameters(parameters: ["fcmToken": newFcmToken], encoding: JSONEncoding.default)
        }
    }
}
