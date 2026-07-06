import Flutter
import Testing
@testable import FlutterPopupManagementFeature

struct FlutterPopupManagementFeatureTests {
    @Test("Flutter runtime이 FlutterViewController를 만든다")
    func flutterRuntimeCreatesViewController() {
        let viewController = FlutterRuntime.shared.makeViewController()

        #expect(viewController is FlutterViewController)
    }
}
