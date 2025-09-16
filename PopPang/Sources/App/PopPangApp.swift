//
//  PopPangApp.swift
//  PopPang
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

@main
struct PopPangApp: App {
    var body: some Scene {
        WindowGroup {
            RootViewSwitcher(rootViewModel: ViewModelFactory.shared.createRoot())
//                .onAppear {
//                    for family in UIFont.familyNames.sorted() {
//                        print("📂 Family: \(family)")
//                        for name in UIFont.fontNames(forFamilyName: family) {
//                            print("   → \(name)")
//                        }
//                    }
//                }
        }
    }
}
