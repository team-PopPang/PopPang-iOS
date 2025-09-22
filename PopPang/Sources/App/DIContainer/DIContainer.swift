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
    
    /// 타입 자체를 Key로 사용하여 의존성을 등록합니다.
    /// - Parameter dependency: 등록할 객체 인스턴스
    /// - Example: `DIContainer.shared.register(NetworkManager())`
    func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency
    }
    
    /// 명시적으로 특정 타입(보통은 프로토콜)을 Key로 지정하여 의존성을 등록합니다.
    /// - Parameters:
    ///   - dependency: 등록할 객체 인스턴스
    ///   - type: 이 객체가 매칭될 인터페이스(예: 프로토콜)
    /// - Example:
    ///   ```swift
    ///   DIContainer.shared.register(NetworkManager(), for: NetworkService.self)
    ///   ```
    func register<T>(_ dependency: T, for type: T.Type) {
      let key = String(describing: type)
      dependencies[key] = dependency
    }
    
    /// 등록된 의존성을 꺼냅니다. 존재하지 않으면 앱을 중단시킵니다.
    /// - Parameter type: 꺼내고 싶은 타입
    /// - Returns: 등록된 의존성 인스턴스
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let dependency = dependencies[key] as? T else {
            preconditionFailure("⚠️ \(key)는 register되지 않았습니다. resolve호출 전에 register 해주세요.")
        }
        return dependency
    }
}

extension DIContainer {
    
    /// 앱 시작 시 의존성들을 한 번에 등록해주는 메서드입니다.
    /// 이 메서드에서 Repository → UseCase 순으로 필요한 객체들을 생성하여 등록합니다.
    static func config(isStub: Bool = false) {
        if isStub {
            configStub()
        } else {
            configLive()
        }
    }

    private static func configStub() {
        // MARK: - Repository
        // MARK: - Uscase
        self.shared.register(StubAppleLoginUsecaseImpl(), for: AppleLoginUsecaseProtocol.self)
        print("✅ Stub UseCase registered")
    }

    private static func configLive() {
        // MARK: - Repository
        // MARK: - Uscase
        self.shared.register(AppleLoginUsecaseImpl(), for: AppleLoginUsecaseProtocol.self)
        print("✅ Live UseCase registered")
    }
}

@propertyWrapper
class Dependency<T> {
    let wrappedValue: T
    init() {
        self.wrappedValue = DIContainer.shared.resolve(T.self)
    }
}
