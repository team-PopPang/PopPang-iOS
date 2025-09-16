//
//  ViewModelFactory.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import Foundation

final class ViewModelFactory {
    static let shared = ViewModelFactory()
    private init() {}
    
    func createRoot() -> RootViewModel {
        RootViewModel()
    }
}
