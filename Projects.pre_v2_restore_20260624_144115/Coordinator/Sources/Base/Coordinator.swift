import BottomSheet
import Foundation
import Observation

@Observable
@MainActor
open class Coordinator<
    Root: Equatable,
    Route: Hashable,
    Sheet: Identifiable,
    Overlay: Identifiable,
    FullScreen: Identifiable,
    BottomSheetRoute: Identifiable
> {
    public var root: Root
    public var routes: [Route]
    public var sheet: Sheet?
    public var overlay: Overlay?
    public var fullScreen: FullScreen?
    public var bottomSheets: [BottomSheetPresentation<BottomSheetRoute>]

    public init(root: Root, initialRoute: Route? = nil) {
        self.root = root
        self.routes = initialRoute.map { [$0] } ?? []
        self.sheet = nil
        self.overlay = nil
        self.fullScreen = nil
        self.bottomSheets = []
    }
}

public extension Coordinator {
    var isPresentingSheet: Bool { sheet != nil }
    var isPresentingOverlay: Bool { overlay != nil }
    var isPresentingFullScreen: Bool { fullScreen != nil }
    var isPresentingBottomSheet: Bool { bottomSheets.isEmpty == false }
    var topBottomSheet: BottomSheetPresentation<BottomSheetRoute>? { bottomSheets.last }
}

public extension Coordinator {
    func switchToRoot(_ root: Root) {
        self.root = root
        popToRoot()
        dismissSheet()
        dismissOverlay()
        dismissFullScreen()
        dismissAllBottomSheets()
    }

    func push(_ route: Route) {
        guard routes.last != route else { return }
        routes.append(route)
    }

    func pop() {
        guard routes.isEmpty == false else { return }
        routes.removeLast()
    }

    func popToRoot() {
        routes.removeAll()
    }

    func pop(to route: Route) {
        guard let index = routes.firstIndex(of: route) else { return }
        routes = Array(routes.prefix(index + 1))
    }
}

public extension Coordinator {
    func presentSheet(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }
}

public extension Coordinator {
    func presentOverlay(_ overlay: Overlay) {
        self.overlay = overlay
    }

    func dismissOverlay() {
        overlay = nil
    }
}

public extension Coordinator {
    func presentFullScreen(_ fullScreen: FullScreen, animated: Bool = true) {
        PresentationAnimation.perform(animated: animated) {
            self.fullScreen = fullScreen
        }
    }

    func dismissFullScreen(animated: Bool = true) {
        PresentationAnimation.perform(animated: animated) {
            fullScreen = nil
        }
    }
}

public extension Coordinator {
    func presentBottomSheet(
        _ route: BottomSheetRoute,
        position: BottomSheetPosition = .relative(0.5),
        switchablePosition: [BottomSheetPosition] = [.hidden, .relative(0.5)]
    ) {
        bottomSheets.append(
            BottomSheetPresentation(
                route: route,
                position: position,
                switchablePositions: switchablePosition
            )
        )
    }

    func dismissBottomSheet() {
        _ = bottomSheets.popLast()
    }

    func dismissBottomSheet(id: BottomSheetRoute.ID) {
        bottomSheets.removeAll { $0.id == id }
    }

    func dismissAllBottomSheets() {
        bottomSheets.removeAll()
    }

    func updateBottomSheetPosition(_ position: BottomSheetPosition) {
        guard let index = bottomSheets.indices.last else { return }
        bottomSheets[index].position = position
    }
}
