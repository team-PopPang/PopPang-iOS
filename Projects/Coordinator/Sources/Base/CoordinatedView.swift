import Core
import SwiftUI

public struct CoordinatorContainer<
    Route: Hashable,
    Sheet: Identifiable,
    Overlay: Identifiable,
    FullScreen: Identifiable,
    BottomSheet: BottomSheetPresentingRoute,
    Content: View,
    Destination: View,
    SheetContent: View,
    OverlayContent: View,
    FullScreenContent: View,
    BottomSheetContent: View
>: View {
    @Bindable private var coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>
    private let content: () -> Content
    private let destination: (Route) -> Destination
    private let sheetView: (Sheet) -> SheetContent
    private let overlayView: (Overlay) -> OverlayContent
    private let fullScreenView: (FullScreen) -> FullScreenContent
    private let bottomSheetView: ((BottomSheet) -> BottomSheetContent)?

    public init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder sheetView: @escaping (Sheet) -> SheetContent,
        @ViewBuilder overlayView: @escaping (Overlay) -> OverlayContent,
        @ViewBuilder fullScreenView: @escaping (FullScreen) -> FullScreenContent,
        @ViewBuilder bottomSheetView: @escaping (BottomSheet) -> BottomSheetContent
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
        self.sheetView = sheetView
        self.overlayView = overlayView
        self.fullScreenView = fullScreenView
        self.bottomSheetView = bottomSheetView
    }

    public var body: some View {
        NavigationStack(path: $coordinator.paths) {
            content()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let route = coordinator.bottomSheet,
                       let bottomSheetView {
                        bottomSheetView(route)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
        }
        .environment(coordinator)
        .sheet(item: $coordinator.sheet) { route in
            sheetView(route)
        }
        .fullScreenCover(item: $coordinator.fullScreen) { route in
            fullScreenView(route)
        }
        .overlay {
            if let route = coordinator.overlay {
                overlayView(route)
            }
        }
        .animation(.snappy, value: coordinator.bottomSheet?.id)
        .animation(.snappy, value: coordinator.bottomSheetPosition)
    }
}

public extension CoordinatorContainer where BottomSheetContent == EmptyView {
    init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder sheetView: @escaping (Sheet) -> SheetContent,
        @ViewBuilder overlayView: @escaping (Overlay) -> OverlayContent,
        @ViewBuilder fullScreenView: @escaping (FullScreen) -> FullScreenContent
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
        self.sheetView = sheetView
        self.overlayView = overlayView
        self.fullScreenView = fullScreenView
        self.bottomSheetView = nil
    }
}

public extension CoordinatorContainer where
    SheetContent == EmptyView,
    OverlayContent == EmptyView,
    FullScreenContent == EmptyView,
    BottomSheetContent == EmptyView
{
    init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
        self.sheetView = { _ in EmptyView() }
        self.overlayView = { _ in EmptyView() }
        self.fullScreenView = { _ in EmptyView() }
        self.bottomSheetView = nil
    }
}

public extension CoordinatorContainer where
    SheetContent == EmptyView,
    OverlayContent == EmptyView,
    BottomSheetContent == EmptyView
{
    init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder fullScreenView: @escaping (FullScreen) -> FullScreenContent
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
        self.sheetView = { _ in EmptyView() }
        self.overlayView = { _ in EmptyView() }
        self.fullScreenView = fullScreenView
        self.bottomSheetView = nil
    }
}

public extension CoordinatorContainer where
    SheetContent == EmptyView,
    OverlayContent == EmptyView,
    FullScreenContent == EmptyView
{
    init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination,
        @ViewBuilder bottomSheetView: @escaping (BottomSheet) -> BottomSheetContent
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
        self.sheetView = { _ in EmptyView() }
        self.overlayView = { _ in EmptyView() }
        self.fullScreenView = { _ in EmptyView() }
        self.bottomSheetView = bottomSheetView
    }
}
