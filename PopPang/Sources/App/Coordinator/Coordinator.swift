//
//  Coordinator.swift
//  DevNote
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

/// T: 화면 경로(Route)를 나타내는 타입(enum Route)
///     - Hashable제약 이유: NavigationStack의 path 관리에 필요
/// R: 모달(sheet)를 나타내는 타입
///     - Identifiable제약 이유: SwiftUI의 .sheet(item:)에서 고유하게 구분할 수 있어야 함
/// ObservableObject: Combime프로토콜
///     - @Published 프로퍼티가 변경되면 SwiftUI뷰가 자동으로 새로 그린다
class Coordinator<T: Hashable, R: Identifiable, O: Identifiable>: ObservableObject {
    @Published var paths: [T] = [] /// 네비게이션 스택 경로 리스트
    @Published var sheet: R? = nil  /// 현재 표시 중인 모달(nil이면 닫힘, 값이 있으면 표시)
    // @Published var sheetDetentsL Set<PresentationDetent> = []
    @Published var overlay: O? = nil /// 공지사항 같은 오버레이
    
    /// 초기 화면 경로 설정 생성자
    /// - initial 값이 있다면 paths 배열을 [initial]로 시작
    /// - 없으면 빈 배열로 시작
    /// ex) Coordinator<Route, MySheet>(initial: .home)
    /// 앱 시작시 .home 경로에서 시작
    init(initial: T? = nil) {
        if let initial = initial {
            self.paths = [initial]
        } else {
            self.paths = []
        }
    }
    
    // 새로운 경로를 네비게이션 스택 끝에 추가
    func push(_ path: T) {
        // 1) 직전 화면과 같은 걍로면 무시하겠다(중복 방지)
        guard paths.last != path else { return }
        print("\n--- push ---")
        // print("  - Before\(paths.map { "\($0)" }.joined(separator: " -> "))")
        paths.append(path)
        // print("  - After: \(paths.map { "\($0)" }.joined(separator: " -> "))")
        let caseName = String(describing: path)
            .components(separatedBy: "(").first ?? String(describing: path)
        print("  - \(caseName)")
    }
    
    // 마지막 경로 제거
    func pop() {
        // 1) 비어있다면 무시
        guard !paths.isEmpty else { return }
        print("\n--- pop ---")
        // print("  - Before: \(paths.map { "\($0)" }.joined(separator: " -> "))")
        paths.removeLast()
        // print("  - After: \(paths.map { "\($0)" }.joined(separator: " -> "))")
    }
    
    // 네비게이션 스택을 루트까지 되돌리기
    func popToRoot() {
        print("\n--- popToRoot ---")
        // print("  - Before: \(paths.map { "\($0)" }.joined(separator: " -> "))")
        paths.removeAll()
        // print("  - After: \(paths.map { "\($0)" }.joined(separator: " -> "))")
    }
    
    // 특정 경로까지 스택을 되돌림
    func pop(to: T) {
        guard let index = paths.firstIndex(of: to) else { return }
        paths = Array(paths.prefix(upTo: index + 1))
    }
    
    // 특정 시트 띄우기
    func presentSheet(_ path: R) {
        sheet = path
    }
    
    // 현재 띄운 sheet 닫기
    func dismissSheet() {
        sheet = nil
    }
    
    // 오버레이 띄우기
    func presentOverlay(overlay: O) {
        self.overlay = overlay
    }
    
    // 오버레이 닫기
    func dismissOverlay() {
        self.overlay = nil
    }
}




//// MARK: - 범용 코드
///// @CoordinatorWrapper<MainRoute, SheetRoute, OverlayRoute> var coordinator
//@propertyWrapper
//struct CoordinatorWrapper<T: Hashable, R: Identifiable, O: Identifiable>: DynamicProperty {
//    @StateObject private var coordinator = Coordinator<T, R, O>()
//    
//    // getter
//    var wrappedValue: Coordinator<T, R, O> {
//        return coordinator
//    }
//}
//
//// MARK: - 메인 코디네이터 전용
///// @MainCoordinator var coordinator
//@propertyWrapper
//struct MainCoordinator: DynamicProperty {
//    @StateObject private var coordinator = Coordinator<MainRoute, SheetRoute, OverlayRoute>()
//    
//    // getter
//    var wrappedValue: Coordinator<MainRoute, SheetRoute, OverlayRoute> {
//        return coordinator
//    }
//}

//// MARK: - 범용 코드
///// @CoordinatorWrapper<MainRoute, SheetRoute, OverlayRoute> var coordinator
//@propertyWrapper
//class CoordinatorWrapper<T: Hashable, R: Identifiable, O: Identifiable>: DynamicProperty {
//    let wrappedValue: Coordinator<T, R, O>
//    
//    init() {
//        self.wrappedValue = Coordinator<T, R, O>()
//    }
//}
//
//// MARK: - 메인 코디네이터 전용
///// @MainCoordinator var coordinator
//@propertyWrapper
//class MainCoordinator {
//    let wrappedValue: Coordinator<MainRoute, SheetRoute, OverlayRoute>
//    
//    init() {
//        self.wrappedValue = Coordinator<MainRoute, SheetRoute, OverlayRoute>()
//    }
//}
