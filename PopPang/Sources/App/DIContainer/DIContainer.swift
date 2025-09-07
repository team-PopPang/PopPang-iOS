//
//  DIContainer.swift
//  DevNote
//
//  Created by 김동현 on 9/6/25.
//

import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private init() {}
    private var dependencies: [String: Any] = [:]
    
    // model, viewController, coordinator를 생성 시점에 등록
    func register<T>(_ object: T) {
        let key = String(describing: T.self)
        dependencies[key] = object
    }
    
    func resolve<T>() -> T? {
        let key = String(describing: T.self)
        guard let object = dependencies[key],
              let object = object as? T else {
            print("⚠️ \(key)는 register되지 았습니다. resolve 호출 전에 register 등록 해주세요")
            return nil
        }
        return object
    }
}

extension DIContainer {
    static func config() async {
        // MARK: - Repository
        
        // MARK: - Uscase
    }
}
