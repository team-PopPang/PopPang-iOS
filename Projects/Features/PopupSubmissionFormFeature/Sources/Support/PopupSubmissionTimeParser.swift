import Domain
import Foundation

enum PopupSubmissionTimeParser {
    static func parse(_ text: String) -> PopupSubmissionLocalTime? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let components = trimmed.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            return nil
        }

        return PopupSubmissionLocalTime(hour: hour, minute: minute)
    }

    static func string(from value: PopupSubmissionLocalTime?) -> String {
        guard let value else { return "" }
        return String(format: "%02d:%02d", value.hour, value.minute)
    }
}
