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
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    static let popupTimeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    // MARK: - 파싱용
    /// Swift의 Date는 시간만표현할 수 없고 항상 날짜 + 시간이 붙어야 한다
    /// 파싱 시 서버의 값과 정확히 일치해야함
    static let serverTimeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}
 
