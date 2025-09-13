//
//  Coordinator.swift
//  DevNote
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

@MainActor
final class Coordinator<T: Hashable, R: Identifiable>: ObservableObject {
    @Published var paths: [T] = []  /// NavigationStack
    @Published var sheet: R? = nil  /// Sheet
    
    init(initial: T? = nil) {
        if let initial = initial {
            self.paths = [initial]
        } else {
            self.paths = []
        }
    }
    
    func push(_ path: T) {
        guard paths.last != path else { return }
        paths.append(path)
    }
    
    func pop() {
        paths.removeLast()
    }
    
    func popToRoot() {
        paths.removeAll()
    }
    
    func pop(to: T) {
        guard let index = paths.firstIndex(of: to) else { return }
        paths = Array(paths.prefix(upTo: index + 1))
    }
    
    func presentSheet(_ path: R) {
        sheet = path
    }
    
    func dismissSheet() {
        sheet = nil
    }
}
