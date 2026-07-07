//
//  Model.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import Foundation

/// 달력에 그릴 각각의 날짜 셀 표현
struct DateValue: Identifiable {
    var id = UUID().uuidString
    var day: Int
    var date: Date
}
