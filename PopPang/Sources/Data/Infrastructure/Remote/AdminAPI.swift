//
//  AdminAPI.swift
//  PopPang
//
//  Created by 김동현 on 12/18/25.
//

import Moya
import Foundation

enum AdminAPI {
    // popup
    case deactivatePopup(userUuid: String, popupUuid: String)
}

extension AdminAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .deactivatePopup(let userUuid, let popupUuid): return "/admin/user/\(userUuid)/popup/\(popupUuid)/deactivate"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .deactivatePopup: return .patch
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .deactivatePopup:
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
