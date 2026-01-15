////
////  TTT.swift
////  PopPang
////
////  Created by 김동현 on 1/14/26.
////
//
//#if false
//
//
//
//
//
//
//import SwiftUI
//import AutoEquatable
//
//@AutoEquatable
//struct ImageCell: View {
//    
//    // popupUuid만 View Equatable 비교 기준으로 사용
//    @AutoRequiredChild(\Popup.popupUuid)
//    let popup: Popup
//    
//    // View Equatable 비교에서 제외
//    @AutoIgnored
//    let isLiked: Bool
//    
//    // 어노테이션이 없으면 Equatable 비교 대상 (함수 타입은 자동 제외)
//    let onTapped: () -> Void
//    
//    var body: some View {
//        
//    }
//}
//
///*
// ────────────────────────────────
// 컴파일 타임에 자동 생성되는 코드
// ────────────────────────────────
//*/
//extension ImageCell: Equatable {
//    static func == (lhs: ImageCell, rhs: ImageCell) -> Bool {
//        // 팝업 식별자가 다르면 다른 View로 판단
//        if lhs.popup.popupUuid != rhs.popup.popupUuid {
//            return false
//        }
//
//        return true
//    }
//}
//
//
//
//
//import SwiftUI
//import AutoEquatable
//
//@AutoEquatable
//struct ImageCell: View {
//    
//    // 특정 속성의 하위 속성을 Equatable 비교 기준으로 사용
//    @AutoRequiredChild(\Popup.popupUuid)
//    let popup: Popup
//    
//    // View Equatable 비교에서 제외
//    @AutoIgnored
//    let isLiked: Bool
//    
//    // 어노테이션이 없으면 Equatable 비교 대상 (함수 타입은 자동 제외)
//    let onTapped: () -> Void
//    
//    var body: some View {
//        
//    }
//}
//
//
//
//
//
///*
// ────────────────────────────────
// 컴파일 타임에 자동 생성되는 코드
// ────────────────────────────────
//*/
//extension ImageCell: Equatable {
//    static func == (lhs: ImageCell, rhs: ImageCell) -> Bool {
//        // 팝업 식별자가 다르면 다른 View로 판단
//        if lhs.popup.popupUuid != rhs.popup.popupUuid {
//            return false
//        }
//
//        return true
//    }
//}
