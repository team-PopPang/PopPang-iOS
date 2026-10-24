import Foundation

/// 인증 세션이 끝나 다시 로그인해야 할 때를 구독자에게 알린다.
///
/// 구독할 때마다 새 stream을 준다. 구독하기 전에 일어난 알림은 받지 않는다.
public final class AuthSessionEvents: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init() {}

    /// 다시 로그인해야 할 때마다 값을 보내는 stream
    public func loginRequired() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        lock.withLock { continuations[id] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.removeContinuation(id)
        }
        return stream
    }

    func notifyLoginRequired() {
        let continuations = lock.withLock { Array(self.continuations.values) }
        continuations.forEach { $0.yield() }
    }

    private func removeContinuation(_ id: UUID) {
        lock.withLock { _ = continuations.removeValue(forKey: id) }
    }
}
