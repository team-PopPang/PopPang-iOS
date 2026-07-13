import SwiftUI
import UIKit
@_implementationOnly import PopPangReactNativeHost
@_implementationOnly import React
@_implementationOnly import React_RCTAppDelegate
@_implementationOnly import ReactAppDependencyProvider

final class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
    override func sourceURL(for bridge: RCTBridge) -> URL? {
        bundleURL()
    }

    override func bundleURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: "main",
            withExtension: "jsbundle",
            subdirectory: "ReactNative"
        ) {
            return url
        }

        if let url = Bundle.main.url(forResource: "main", withExtension: "jsbundle") {
            return url
        }

        fatalError("""
        main.jsbundle을 찾을 수 없습니다.
        scripts/download-rn-release.sh를 실행하고 Build Phases > Copy Bundle Resources 설정을 확인해 주세요.
        """)
    }
}

final class ReactViewController: UIViewController {
    private let moduleName: String
    private let initialProperties: [String: Any]?
    private var reactNativeFactory: RCTReactNativeFactory?
    private var reactNativeFactoryDelegate: RCTReactNativeFactoryDelegate?

    init(
        moduleName: String,
        initialProperties: [String: Any]? = nil
    ) {
        self.moduleName = moduleName
        self.initialProperties = initialProperties
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let delegate = ReactNativeDelegate()
        delegate.dependencyProvider = RCTAppDependencyProvider()

        let factory = RCTReactNativeFactory(delegate: delegate)
        reactNativeFactoryDelegate = delegate
        reactNativeFactory = factory
        view = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }
}

struct ReactNativeScreen: UIViewControllerRepresentable {
    final class EventHandlerCoordinator {
        let id = UUID()
    }

    let moduleName: String
    let initialProperties: [String: Any]?
    let onNativeEvent: ((String) -> Void)?

    private static var eventHandlerOwnerID: UUID?

    func makeCoordinator() -> EventHandlerCoordinator {
        EventHandlerCoordinator()
    }

    func makeUIViewController(context: Context) -> ReactViewController {
        installEventHandler(for: context.coordinator)
        return ReactViewController(
            moduleName: moduleName,
            initialProperties: initialProperties
        )
    }

    func updateUIViewController(
        _ uiViewController: ReactViewController,
        context: Context
    ) {
        installEventHandler(for: context.coordinator)
    }

    static func dismantleUIViewController(
        _ uiViewController: ReactViewController,
        coordinator: EventHandlerCoordinator
    ) {
        guard eventHandlerOwnerID == coordinator.id else { return }
        PopPangHostAction.setEventHandler(nil)
        eventHandlerOwnerID = nil
    }

    private func installEventHandler(for coordinator: EventHandlerCoordinator) {
        Self.eventHandlerOwnerID = coordinator.id
        PopPangHostAction.setEventHandler(onNativeEvent)
    }
}
