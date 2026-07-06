import ComposableArchitecture

@Reducer
public struct FlutterPopupManagementFeature {
    @ObservableState
    public struct State: Equatable {
        public var title: String
        public var isFlutterViewAttached: Bool
        public var bridgeStatusText: String

        public init(
            title: String = "Flutter Popup Management",
            isFlutterViewAttached: Bool = false,
            bridgeStatusText: String = "Flutter view is not connected yet."
        ) {
            self.title = title
            self.isFlutterViewAttached = isFlutterViewAttached
            self.bridgeStatusText = bridgeStatusText
        }
    }

    public enum Action: Equatable {
        case onAppear
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
