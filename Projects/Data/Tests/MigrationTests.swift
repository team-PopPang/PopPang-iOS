import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct MigrationTests {
    @Test("가입 OS 채우기는 V2 경로에 Access Token으로 IOS를 보낸다")
    func fillSignupOsRequestMatchesContract() throws {
        let request = try MoyaProvider<MigrationAPI>.defaultEndpointMapping(for: .fillSignupOs).urlRequest()

        #expect(request.url?.path == "/api/v2/user/signup-os")
        #expect(request.httpMethod == "PATCH")
        #expect(try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: String] == ["signupOs": "IOS"])
        #expect(MigrationAPI.fillSignupOs.resolvedAuthorization == .access)
    }

    @Test("아직 하지 않은 사용자는 요청을 보내고, 성공하면 마쳤다고 기록한다")
    func pendingMigrationRunsAndIsRecorded() async throws {
        let context = Context(statusCode: 200)

        try await context.usecase.runPendingMigrations(userUuid: "user-1")

        #expect(context.requestCount.value == 1)
        #expect(context.repository.isSignupOsFilled(userUuid: "user-1"))
    }

    @Test("이미 마친 사용자는 요청을 보내지 않는다")
    func completedMigrationIsSkipped() async throws {
        let context = Context(statusCode: 200)
        context.repository.markSignupOsFilled(userUuid: "user-1")

        try await context.usecase.runPendingMigrations(userUuid: "user-1")

        #expect(context.requestCount.value == 0)
    }

    @Test("실패하면 기록하지 않아 다음 실행 때 다시 보낸다")
    func failedMigrationIsNotRecorded() async throws {
        let context = Context(statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await context.usecase.runPendingMigrations(userUuid: "user-1")
        }
        #expect(!context.repository.isSignupOsFilled(userUuid: "user-1"))
    }

    @Test("요청을 기다리는 동안 취소되면 기록하지 않는다")
    func cancelledMigrationIsNotRecorded() async throws {
        let context = Context(statusCode: 200)

        // Moya도 `Task`를 내보내서 Swift Concurrency의 `Task`를 직접 가리킨다.
        let task = _Concurrency.Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await context.usecase.runPendingMigrations(userUuid: "user-1")
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(context.requestCount.value == 0)
        #expect(!context.repository.isSignupOsFilled(userUuid: "user-1"))
    }

    @Test("기록은 사용자별이라 다른 계정은 한 번 더 보낸다")
    func recordsArePerUser() async throws {
        let context = Context(statusCode: 200)
        context.repository.markSignupOsFilled(userUuid: "user-1")

        try await context.usecase.runPendingMigrations(userUuid: "user-2")

        #expect(context.requestCount.value == 1)
        #expect(context.repository.isSignupOsFilled(userUuid: "user-1"))
        #expect(context.repository.isSignupOsFilled(userUuid: "user-2"))
    }
}

/// 정해 둔 상태 코드를 돌려주고 보낸 요청 수를 세는 마이그레이션 Repository와 Usecase
private struct Context {
    let requestCount = Counter()
    let repository: MigrationRepositoryImpl
    let usecase: MigrationUsecaseImpl

    init(statusCode: Int) {
        let networkProvider = NetworkProvider(stubClosure: MoyaProvider.immediatelyStub)
        let requestCount = requestCount

        let repository = MigrationRepositoryImpl(
            store: InMemoryStore(),
            makeProvider: {
                networkProvider.makeProvider(
                    endpointClosure: { target in
                        Endpoint(
                            url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                            sampleResponseClosure: {
                                requestCount.increase()
                                return .networkResponse(statusCode, Data())
                            },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers
                        )
                    }
                )
            }
        )
        self.repository = repository
        self.usecase = MigrationUsecaseImpl(migrationRepository: repository)
    }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.withLock { _value }
    }

    func increase() {
        lock.withLock { _value += 1 }
    }
}

/// 메모리에 값을 두는 저장 수단
private final class InMemoryStore: Storing, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Any] = [:]

    func value<T>(forKey key: String) -> T? {
        lock.withLock { values[key] as? T }
    }

    func set<T>(_ value: T, forKey key: String) throws {
        lock.withLock { values[key] = value }
    }

    func removeValue(forKey key: String) {
        lock.withLock { _ = values.removeValue(forKey: key) }
    }
}
