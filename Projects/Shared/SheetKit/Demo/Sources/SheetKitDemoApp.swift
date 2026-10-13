import SwiftUI

@main
struct SheetKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                MapSheetDemoView()
                    .tabItem {
                        Label("지도", systemImage: "map")
                    }

                Text("시트가 없는 탭")
                    .tabItem {
                        Label("다른 탭", systemImage: "square.grid.2x2")
                    }
            }
        }
    }
}
