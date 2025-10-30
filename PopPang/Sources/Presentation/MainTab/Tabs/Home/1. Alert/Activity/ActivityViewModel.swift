//
//  ActivityViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import Foundation

final class ActivityViewModel: ObservableObject {
    let userUuid: String
    init(userUuid: String) {
        self.userUuid = userUuid
    }
}
