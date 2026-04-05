//
//  String+.swift
//  PopPang
//
//  Created by 김동현 on 10/5/25.
//

import Foundation

extension LocalizationKey {
    var localized: String {
        NSLocalizedString(rawValue, comment: "")
    }

    func localized(comment: String) -> String {
        NSLocalizedString(rawValue, comment: comment)
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(comment: String) -> String {
        NSLocalizedString(self, comment: comment)
    }

    var shortAddress: String {
        let parts = self.split(separator: " ")
        if parts.count >= 2 {
            return parts[0...1].joined(separator: " ")
        } else {
            return self
        }
    }
}
