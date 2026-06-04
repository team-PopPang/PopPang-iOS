import Foundation
import Observation

public enum EmptyRoute: Hashable {}

public enum EmptySheetRoute: Identifiable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyOverlayRoute: Identifiable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyFullScreenRoute: Identifiable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyBottomSheetRoute: BottomSheetPresentingRoute {
    public var id: String {
        switch self {}
    }

    public var preferredDetent: BottomSheetDetent {
        switch self {}
    }

    public var supportedDetents: [BottomSheetDetent] {
        switch self {}
    }
}

@Observable
@MainActor
open class Coordinator<
    Route: Hashable,
    Sheet: Identifiable,
    Overlay: Identifiable,
    FullScreen: Identifiable,
    BottomSheet: BottomSheetPresentingRoute
> {
    public var paths: [Route] = []
    public var sheet: Sheet?
    public var overlay: Overlay?
    public var fullScreen: FullScreen?
    public var bottomSheet: BottomSheet?
    public var bottomSheetPosition: BottomSheetDetent = .hidden

    public init(initial: Route? = nil) {
        if let initial {
            self.paths = [initial]
        }
    }

    public func push(_ route: Route) {
        guard paths.last != route else { return }
        paths.append(route)
    }

    public func pop() {
        guard paths.isEmpty == false else { return }
        paths.removeLast()
    }

    public func popToRoot() {
        paths.removeAll()
    }

    public func pop(to route: Route) {
        guard let index = paths.firstIndex(of: route) else { return }
        paths = Array(paths.prefix(index + 1))
    }

    public func presentSheet(_ route: Sheet) {
        sheet = route
    }

    public func dismissSheet() {
        sheet = nil
    }

    public func presentOverlay(_ route: Overlay) {
        overlay = route
    }

    public func dismissOverlay() {
        overlay = nil
    }

    public func presentFullScreen(_ route: FullScreen) {
        fullScreen = route
    }

    public func dismissFullScreen() {
        fullScreen = nil
    }

    public func presentBottomSheet(_ route: BottomSheet) {
        bottomSheet = route
        bottomSheetPosition = route.preferredDetent
    }

    public func updateBottomSheetPosition(_ detent: BottomSheetDetent) {
        bottomSheetPosition = detent
    }

    public func dismissBottomSheet() {
        bottomSheet = nil
        bottomSheetPosition = .hidden
    }

    public var supportedBottomSheetDetents: [BottomSheetDetent] {
        bottomSheet?.supportedDetents ?? []
    }
}
