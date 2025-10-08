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
}

extension PopupAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .getPopupList: return "/popup"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getPopupList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getPopupList:
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
