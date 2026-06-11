import Foundation

public extension String {
    var shortAddress: String {
        let parts = split(separator: " ")
        guard parts.count >= 2 else { return self }
        return parts[0...1].joined(separator: " ")
    }
}
