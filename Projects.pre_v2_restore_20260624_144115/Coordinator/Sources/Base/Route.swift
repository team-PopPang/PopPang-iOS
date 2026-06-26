public enum DefaultCoordinatorRoot: Equatable, Sendable {
    case root
}

public enum EmptyRoute: Hashable, Sendable {}

public enum EmptySheetRoute: Identifiable, Sendable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyOverlayRoute: Identifiable, Sendable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyFullScreenRoute: Identifiable, Sendable {
    public var id: String {
        switch self {}
    }
}

public enum EmptyBottomSheetRoute: Identifiable, Sendable {
    public var id: String {
        switch self {}
    }
}
