//
//  DateFormatter+.swift
//  PopPang
//
//  Created by 김동현 on 9/27/25.
//

import Foundation

extension DateFormatter {
    static let popupDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YY.MM.dd"
        return formatter
    }()
    
    static let popupTimeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
