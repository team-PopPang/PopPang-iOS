//
//  PopupAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Moya
import Foundation

enum PopupAPI {
    case getPopupList
    case addFavorite(userUuid: String, popupUuid: String)
    case removeFavorite(userUuid: String, popupUuid: String)
    case getFavoriteList(userUuid: String)
}

extension PopupAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .getPopupList: return "/popup"
        case .addFavorite: return "/favorite"
        case .removeFavorite: return "/favorite"
        case .getFavoriteList(let userUuid): return "/favorite/popup/\(userUuid)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getPopupList: return .get
        case .addFavorite: return .post
        case .removeFavorite: return .delete
        case .getFavoriteList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getPopupList:
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
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
