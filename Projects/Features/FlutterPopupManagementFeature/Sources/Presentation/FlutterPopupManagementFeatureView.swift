import SwiftUI
import UIKit

public struct FlutterPopupManagementFeatureView: View {
    @State private var isSheetPresented = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: Route.flutterPush) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(.blue)

                        Text("Flutter Demo Push")
                            .foregroundStyle(.black)
                    }
                }
                
                Button {
                    isSheetPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.blue)

                        Text("Flutter Demo Sheet")
                            .foregroundStyle(.black)
                    }
                }
            }
            .navigationTitle("SwiftUI Root")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .flutterPush:
                    FlutterPopupManagementPushDestinationView()
                        .ignoresSafeArea()
                        // .navigationTitle("Flutter Demo Push")
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                FlutterPopupManagementSheetDestinationView()
                    .ignoresSafeArea()
            }
        }
    }
}

private enum Route: Hashable {
    case flutterPush
}

private struct FlutterPopupManagementPushDestinationView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let flutterViewController = FlutterEngine.shared.makeViewController()
        return flutterViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private struct FlutterPopupManagementSheetDestinationView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let flutterViewController = FlutterEngine.shared.makeViewController()
        flutterViewController.title = "Flutter Demo Sheet"

        let navigationController = UINavigationController(rootViewController: flutterViewController)
        navigationController.modalPresentationStyle = .fullScreen
        
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
