import Foundation
import Core
import SwiftUI
import UIKit

private enum VersionUpdateConfig {
    static let lookupURL = URL(string: "https://itunes.apple.com/lookup?id=6753014613&country=KR" + "&timestamp=\(Int(Date().timeIntervalSince1970))")
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6753014613")
}

extension View {
    func versionUpdateAlert() -> some View {
        modifier(VersionUpdateModifier())
    }
}

private struct VersionUpdateModifier: ViewModifier {
    @State private var showAlert = false
    @State private var latestVersion: String?
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task {
                await checkForAppUpdates()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("앱 업데이트 필요"),
                    message: Text("새로운 기능과 성능 개선을 위해 최신 버전 (\(latestVersion ?? ""))을 사용해 보세요!"),
                    dismissButton: .default(Text("업데이트")) {
                        guard let url = VersionUpdateConfig.appStoreURL else { return }
                        UIApplication.shared.open(url)
                    }
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await checkForAppUpdates()
                    }
                }
            }
    }

    private func checkForAppUpdates() async {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        guard let latestVersion = await fetchLatestVersion() else { return }

        if currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending {
            await MainActor.run {
                self.latestVersion = latestVersion
                self.showAlert = true
            }
        }
    }

    private func fetchLatestVersion() async -> String? {
        guard let url = VersionUpdateConfig.lookupURL else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let results = json?["results"] as? [[String: Any]]
            return results?.first?["version"] as? String
        } catch {
            return nil
        }
    }
}
