import NMapsMap
import SwiftUI

@main
struct MapFeatureDemoApp: App {
    init() {
        MapFeatureDemoConfiguration.configureNaverMap()
    }

    var body: some Scene {
        WindowGroup {
            NaverMapDemoRootView()
        }
    }
}

enum MapFeatureDemoConfiguration {
    static var naverMapClientID: String? {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "NMFClientID") as? String else {
            return nil
        }

        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedClientID.isEmpty == false,
              trimmedClientID.hasPrefix("$(") == false else {
            return nil
        }

        return trimmedClientID
    }

    static func configureNaverMap() {
        guard let naverMapClientID else { return }
        NMFAuthManager.shared().ncpKeyId = naverMapClientID
    }
}
