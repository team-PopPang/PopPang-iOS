//
//  UIApplication+.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .endEditing(force)
    }
}
