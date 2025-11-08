//
//  String+.swift
//  PopPang
//
//  Created by 김동현 on 10/5/25.
//

import Foundation

extension String {
    var shortAddress: String {
        let parts = self.split(separator: " ")
        if parts.count >= 2 {
            return parts[0...1].joined(separator: " ")
        } else {
            return self
        }
    }
}
