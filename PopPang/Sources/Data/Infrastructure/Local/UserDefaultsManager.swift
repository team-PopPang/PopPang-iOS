//
//  UserDefaultsManager.swift
//  PopPang
//
//  Created by 김동현 on 10/22/25.
//

import Foundation

struct UserDefaultsManager {
    static let key = "recentCategories"
    
    static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    static func save(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: key)
    }
    
    static func add(_ newKeyword: String) {
        var current = load()
        // 중복 제거 및 최근 검색어는 앞으로 오도록
        current.removeAll { $0 == newKeyword }
        current.insert(newKeyword, at: 0)
        // 최근 5개만 저장
        if current.count > 5 {
            current = Array(current.prefix(5))
        }
        save(current)
    }
    
    static func remove(_ keyword: String) {
        var current = load()
        current.removeAll { $0 == keyword }
        save(current)
    }
    
    
    static let fcmTokenKey = "fcmToken"
    
    static func saveFcmToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: fcmTokenKey)
    }

    static func loadFcmToken() -> String? {
        UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    static func removeFcmToken() {
        UserDefaults.standard.removeObject(forKey: fcmTokenKey)
    }
}
