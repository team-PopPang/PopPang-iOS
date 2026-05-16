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

//@propertyWrapper
//struct LessThan100 {
//    var wrappedValue: Int {
//        didSet {
//            self.wrappedValue = min(wrappedValue, 100)
//        }
//    }
//    
//    init(wrappedValue: Int) {
//        self.wrappedValue = min(wrappedValue, 100)
//    }
//}



//@propertyWrapper
//struct LessThan100 {
//    private var value: Int
//    
//    var wrappedValue: Int {
//        get { value }
//        set { value = min(newValue, 100) }
//    }
//    
//    init(wrappedValue: Int) {
//        self.value = min(wrappedValue, 100)
//    }
//}
