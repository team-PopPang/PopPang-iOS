import BottomSheet

public struct BottomSheetPresentation<Route: Identifiable>: Identifiable {
    public let route: Route
    public var position: BottomSheetPosition
    public var switchablePositions: [BottomSheetPosition]
    public var id: Route.ID { route.id }

    public init(
        route: Route,
        position: BottomSheetPosition,
        switchablePositions: [BottomSheetPosition]
    ) {
        self.route = route
        self.position = position
        self.switchablePositions = switchablePositions
    }
}
