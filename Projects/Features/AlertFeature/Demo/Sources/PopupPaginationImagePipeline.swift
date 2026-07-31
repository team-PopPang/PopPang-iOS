import Foundation
import OSLog
import UIKit

final class PopupPaginationImagePipeline: @unchecked Sendable {
    typealias ImageCompletion = @MainActor (UIImage?) -> Void

    private struct PrefetchOperation {
        let task: URLSessionDataTask
        var tokens: Set<UUID>
    }

    private let session: URLSession
    private let lock = NSLock()
    private let logger = Logger(
        subsystem: "com.poppang.demo.alert",
        category: "ImagePrefetch"
    )

    private var prefetchedImages: [URL: UIImage] = [:]
    private var prefetchOperations: [URL: PrefetchOperation] = [:]
    private var prefetchURLsByToken: [UUID: URL] = [:]
    private var visibleTasks: [UUID: URLSessionDataTask] = [:]
    private var visibleCompletions: [UUID: ImageCompletion] = [:]
    private var visibleWaiters: [URL: [UUID: ImageCompletion]] = [:]
    private var visibleWaiterURLsByID: [UUID: URL] = [:]

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    @discardableResult
    func prefetchImage(at url: URL) -> UUID {
        let token = UUID()
        var taskToResume: URLSessionDataTask?

        lock.lock()
        prefetchURLsByToken[token] = url

        if prefetchedImages[url] == nil {
            if var operation = prefetchOperations[url] {
                operation.tokens.insert(token)
                prefetchOperations[url] = operation
            } else {
                let task = session.dataTask(with: request(for: url)) { [weak self] data, response, error in
                    self?.completePrefetch(
                        at: url,
                        data: data,
                        response: response,
                        error: error
                    )
                }
                prefetchOperations[url] = PrefetchOperation(
                    task: task,
                    tokens: [token]
                )
                taskToResume = task
            }
        }
        lock.unlock()

        if taskToResume != nil {
            logger.debug("prefetch start: \(url.absoluteString, privacy: .public)")
        }
        taskToResume?.resume()
        return token
    }

    func cancelPrefetch(_ token: UUID) {
        var taskToCancel: URLSessionDataTask?
        var cancelledURL: URL?

        lock.lock()
        if let url = prefetchURLsByToken.removeValue(forKey: token) {
            cancelledURL = url

            if var operation = prefetchOperations[url] {
                operation.tokens.remove(token)
                let hasVisibleWaiters = visibleWaiters[url]?.isEmpty == false

                if operation.tokens.isEmpty, !hasVisibleWaiters {
                    prefetchOperations.removeValue(forKey: url)
                    taskToCancel = operation.task
                } else {
                    prefetchOperations[url] = operation
                }
            }

            let hasRemainingTokens = prefetchURLsByToken.values.contains(url)
            if !hasRemainingTokens {
                prefetchedImages.removeValue(forKey: url)
            }
        }
        lock.unlock()

        taskToCancel?.cancel()
        if let cancelledURL {
            logger.debug("prefetch cancel: \(cancelledURL.absoluteString, privacy: .public)")
        }
    }

    @discardableResult
    func loadImage(
        at url: URL,
        completion: @escaping ImageCompletion
    ) -> UUID {
        let loadID = UUID()
        var prefetchedImage: UIImage?
        var taskToResume: URLSessionDataTask?
        var joinedPrefetch = false

        lock.lock()
        if let image = prefetchedImages.removeValue(forKey: url) {
            prefetchedImage = image
        } else if prefetchOperations[url] != nil {
            visibleWaiters[url, default: [:]][loadID] = completion
            visibleWaiterURLsByID[loadID] = url
            joinedPrefetch = true
        } else {
            let task = session.dataTask(with: request(for: url)) { [weak self] data, response, error in
                self?.completeVisibleLoad(
                    id: loadID,
                    data: data,
                    response: response,
                    error: error
                )
            }
            visibleTasks[loadID] = task
            visibleCompletions[loadID] = completion
            taskToResume = task
        }
        lock.unlock()

        if let prefetchedImage {
            logger.debug("prefetch consume: \(url.absoluteString, privacy: .public)")
            Task { @MainActor in
                completion(prefetchedImage)
            }
        } else if joinedPrefetch {
            logger.debug("prefetch join: \(url.absoluteString, privacy: .public)")
        } else {
            logger.debug("visible load: \(url.absoluteString, privacy: .public)")
            taskToResume?.resume()
        }

        return loadID
    }

    func cancelImageLoad(_ loadID: UUID) {
        var taskToCancel: URLSessionDataTask?

        lock.lock()
        taskToCancel = visibleTasks.removeValue(forKey: loadID)
        visibleCompletions.removeValue(forKey: loadID)

        if let url = visibleWaiterURLsByID.removeValue(forKey: loadID) {
            visibleWaiters[url]?.removeValue(forKey: loadID)
            if visibleWaiters[url]?.isEmpty == true {
                visibleWaiters.removeValue(forKey: url)

                if let operation = prefetchOperations[url],
                   operation.tokens.isEmpty
                {
                    prefetchOperations.removeValue(forKey: url)
                    taskToCancel = operation.task
                }
            }
        }
        lock.unlock()

        taskToCancel?.cancel()
    }

    deinit {
        lock.lock()
        let tasks = prefetchOperations.values.map(\.task)
            + Array(visibleTasks.values)
        prefetchOperations.removeAll()
        visibleTasks.removeAll()
        visibleCompletions.removeAll()
        visibleWaiters.removeAll()
        prefetchedImages.removeAll()
        lock.unlock()

        tasks.forEach { $0.cancel() }
        session.invalidateAndCancel()
    }
}

private extension PopupPaginationImagePipeline {
    func request(for url: URL) -> URLRequest {
        URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
    }

    func completePrefetch(
        at url: URL,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        let image = Self.decodeImage(
            data: data,
            response: response,
            error: error
        )
        var completions: [ImageCompletion] = []

        lock.lock()
        let operation = prefetchOperations.removeValue(forKey: url)
        let waiters = visibleWaiters.removeValue(forKey: url) ?? [:]
        waiters.keys.forEach { visibleWaiterURLsByID.removeValue(forKey: $0) }
        completions = Array(waiters.values)

        if completions.isEmpty,
           operation?.tokens.isEmpty == false,
           let image
        {
            prefetchedImages[url] = image
        }
        lock.unlock()

        guard !completions.isEmpty else { return }
        Task { @MainActor in
            completions.forEach { $0(image) }
        }
    }

    func completeVisibleLoad(
        id: UUID,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        let image = Self.decodeImage(
            data: data,
            response: response,
            error: error
        )
        let completion: ImageCompletion?

        lock.lock()
        visibleTasks.removeValue(forKey: id)
        completion = visibleCompletions.removeValue(forKey: id)
        lock.unlock()

        guard let completion else { return }
        Task { @MainActor in
            completion(image)
        }
    }

    static func decodeImage(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> UIImage? {
        guard error == nil,
              let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode,
              let data
        else {
            return nil
        }
        return UIImage(data: data)
    }
}
