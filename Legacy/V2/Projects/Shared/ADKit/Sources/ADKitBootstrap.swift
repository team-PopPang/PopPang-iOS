import GoogleMobileAds

public enum ADKitBootstrap {
    public static func start() {
        MobileAds.shared.start(completionHandler: nil)
    }
}
