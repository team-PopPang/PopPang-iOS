import Foundation

struct DateValue: Identifiable {
    let id = UUID().uuidString
    let day: Int
    let date: Date
}
