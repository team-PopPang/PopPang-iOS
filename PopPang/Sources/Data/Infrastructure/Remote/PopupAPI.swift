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
    case getPopupList                        /// 전체 팝업
    case getUpcomingPopupList                /// 다가오는 팝업
    case getInProgressPopupList              /// 진행 중인 팝업
    case searchPopupList(searchText: String) /// 팝업 검색
    
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
        case .getPopupList: return "/popup"
        case .getUpcomingPopupList: return "/popup/upcoming"
        case .getInProgressPopupList: return "/popup/inProgress"
        case .searchPopupList: return "/popup/search"
        case .addFavorite: return "/favorite"
        case .removeFavorite: return "/favorite"
        case .getFavoriteList(let userUuid): return "/favorite/popup/\(userUuid)"
        case .getRegionList: return "/popup/regions/districts"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getPopupList: return .get
        case .getUpcomingPopupList: return .get
        case .getInProgressPopupList: return .get
        case .searchPopupList: return .get
        case .addFavorite: return .post
        case .removeFavorite: return .delete
        case .getFavoriteList: return .get
        case .getRegionList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getPopupList:
            return .requestPlain
        case .getUpcomingPopupList:
            return .requestPlain
        case .getInProgressPopupList:
            return .requestPlain
        case .searchPopupList(let searchText):
            return .requestParameters(parameters: ["q": searchText],
                                      encoding: URLEncoding.queryString)
            
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
