//
//  Test.swift
//  PopPang
//
//  Created by 김동현 on 1/8/26.
//

import Foundation
import AutoEquatable

@AutoEquatable
struct UserTest {
    let id: Int
    let name: String
    let onTap: () -> Void
}

