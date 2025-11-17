//
//  PopupAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Moya
import Foundation

enum PopupAPI {
    // popup
    case getPopupList                         /// 팝업 전체 조회
    case getUpcomingPopupList                 /// 다가오는 팝업 조회
    case getInProgressPopupList               /// 진행 중인 팝업 조회
    case searchPopupList(searchText: String)  /// 팝업 검색
    case increaseViewCount(popupUuid: String) /// 팝업 조회수 증가
    
    // 개인화 popup
    case getPersonalPopupList(userUuid: String)                            /// 팝업 전체 조회
    case getPersonalUseerRecommendPopupList(userUuid: String)              /// 유저별 개인화 추천 팝업 조회
    case getPersonalUpcomingPopupList(userUuid: String)                    /// 다가오는 팝업 조회
    case getPersonalFilteredPopupList(userUuid: String,                    /// 홈 화면용 팝업 필터 조회
                                      region: String,
                                      district: String,
                                      homeSortStandard: String)
    case getPersonalSearchPopupList(userUuid: String, searchText: String)  /// 팝업 검색
    case getPersonalMapFilteredPopupList(userUuid: String,
                                         region: String,
                                         district: String,
                                         latitude: Double?,
                                         longitude: Double?,
                                         mapSortStandard: String)
    
    // 알림 popup
    case getAlertPopupList(userUuid: String)
    case removeAlertPopup(userUuid: String, popupUuid: String)
    
    // favorite
    case addFavorite(userUuid: String, popupUuid: String)
    case removeFavorite(userUuid: String, popupUuid: String)
    case getFavoriteList(userUuid: String)
    
    // 지역/구 목록 조회
    case getRegionList
}

extension PopupAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        // popup
        case .getPopupList: return "/popup"
        case .getUpcomingPopupList: return "/popup/upcoming"
        case .getInProgressPopupList: return "/popup/inProgress" 
        case .searchPopupList: return "/popup/search"
        case .increaseViewCount(let popupUuid): return "/popup/\(popupUuid)/view"
            
        // 개인화 popup
        case .getPersonalPopupList(let userUuid): return "/users/\(userUuid)/popups"                                         /// 팝업 전체 조회
        case .getPersonalUseerRecommendPopupList(let userUuid): return "/users/\(userUuid)/popups/recommend"                 /// 유저별 개인화 추천 팝업 조회
        case .getPersonalUpcomingPopupList(let userUuid): return "/users/\(userUuid)/popups/upcoming"                        /// 다가오는 팝업 조회
        case .getPersonalFilteredPopupList(let userUuid, _, _, _): return "/users/\(userUuid)/popups/filtered/home"          /// 홈 팝업 필터 조회
        case .getPersonalSearchPopupList(let userUuid, _): return "/users/\(userUuid)/popups/search"                         /// 팝업 검색
        case .getPersonalMapFilteredPopupList(let userUuid, _, _, _, _, _): return "/users/\(userUuid)/popups/filtered/map"  /// 맵 팝업 필터 조회
        
        // 알림 popup
        case .getAlertPopupList(let userUuid): return "/users/\(userUuid)/alert/popups"
        case .removeAlertPopup(let userUuid, _): return "/users/\(userUuid)/alert"
            
        // favorite
        case .addFavorite: return "/favorite"
        case .removeFavorite: return "/favorite"
        case .getFavoriteList(let userUuid): return "/favorite/popup/\(userUuid)"
            
        // 지역/구 목록 조회
        case .getRegionList: return "/popup/regions/districts"
        }
    }
    
    var method: Moya.Method {
        switch self {
        // popup
        case .getPopupList: return .get
        case .getUpcomingPopupList: return .get
        case .getInProgressPopupList: return .get
        case .searchPopupList: return .get
        case .increaseViewCount: return .post
            
        // 개인화 popup
        case .getPersonalPopupList: return .get
        case .getPersonalUseerRecommendPopupList: return .get
        case .getPersonalUpcomingPopupList: return .get
        case .getPersonalFilteredPopupList: return .get
        case .getPersonalSearchPopupList: return .get
        case .getPersonalMapFilteredPopupList: return .get
            
        // 알림 popup
        case .getAlertPopupList: return .get
        case .removeAlertPopup: return .delete
            
        // favorite
        case .addFavorite: return .post
        case .removeFavorite: return .delete
        case .getFavoriteList: return .get
            
        // 지역/구 목록 조회
        case .getRegionList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        // popup
        case .getPopupList:
            return .requestPlain
        case .getUpcomingPopupList:
            return .requestPlain
        case .getInProgressPopupList:
            return .requestPlain
        case .searchPopupList(let searchText):
            return .requestParameters(parameters: ["q": searchText],
                                      encoding: URLEncoding.queryString)
            
        // 개인화 popup
        case .getPersonalPopupList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid],
                                      encoding: URLEncoding.queryString)
        case .getPersonalUseerRecommendPopupList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid],
                                      encoding: URLEncoding.queryString)
        case .getPersonalUpcomingPopupList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid],
                                      encoding: URLEncoding.queryString)
        case .getPersonalFilteredPopupList(_,
                                           let region,
                                           let district,
                                           let homeSortStandard):
            return .requestParameters(parameters: ["region": region,
                                                   "district": district,
                                                   "homeSortStandard": homeSortStandard
                                                  ],
                                      encoding: URLEncoding.queryString)
        case .getPersonalSearchPopupList(_, let searchText):
            return .requestParameters(parameters: ["q": searchText],
                                      encoding: URLEncoding.queryString)
        case .getPersonalMapFilteredPopupList(_,
                                              let region,
                                              let district,
                                              let latitude,
                                              let longitude,
                                              let mapSortStandard):
            var params: [String: Any] = [
                "region": region,
                "district": district,
                "mapSortStandard": mapSortStandard
            ]
            if let lat = latitude, let lon = longitude {
                params["latitude"] = lat
                params["longitude"] = lon
            }
            return.requestParameters(parameters: params, encoding: URLEncoding.queryString)
            
        // 알림 popup
        case .getAlertPopupList(_):
            return .requestPlain
            
        case .removeAlertPopup(_, let popupUuid):
            return .requestParameters(parameters: ["popupUuid": popupUuid],
                                      encoding: JSONEncoding.default)
            
        // favorite
        case .increaseViewCount:
            return .requestPlain
            
        case .addFavorite(let userUuid, let popupUuid):
            return .requestParameters(parameters: [
                                                    "userUuid": userUuid,
                                                    "popupUuid": popupUuid
                                                ],
                                      encoding: JSONEncoding.default)
        case .removeFavorite(let userUuid, let popupUuid):
            return .requestParameters(parameters: [
                                                    "userUuid": userUuid,
                                                    "popupUuid": popupUuid
                                                ],
                                      encoding: JSONEncoding.default)
        case .getFavoriteList:
            return .requestPlain
            
        // 지역/구 목록 조회
        case .getRegionList:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
