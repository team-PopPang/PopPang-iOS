import Foundation

@MainActor
public protocol HomeFeatureNavigating: AnyObject {
    func showSearch()
    func showPopupDetail()
}
