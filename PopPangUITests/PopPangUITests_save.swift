//
//  PopPangUITests.swift
//  PopPangUITests
//
//  Created by 김동현 on 1/16/26.
//

/*
import XCTest

final class PopPangUITestsSave: XCTestCase {

    // MARK: - 이 클래스 안의 각 테스트 메서드 실행 직전마다 호출
    /// testExample() 실행 전 1번
    /// testLaunchPerformance() 실행 전 1번
    /// throws?
    /// - 준비 과정에서 실패할 수 있기 때문
    /// - 예: 테스트 계정 세팅 실패, 초기 상태 구성 실패 등
    /// - → throw 하면 해당 테스트를 실패로 처리하고 종료 가능.
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        /// true면: assert 실패해도 계속 다음 줄 실행
        /// false면: assert 실패하면 그 테스트를 즉시 중단
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    // MARK: - 테스트 후 정리
    /// 각 테스트 메서드가 끝난 직후마다 호출됨
    /// - 테스트가 만든 상태를 정리
    /// - 로그아웃
    /// - 테스트 데이터 삭제(가능하면)
    /// - 메모리 누수 확인 도구 등을 붙일 때도 씀
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        /// 화면 회전 고정(세로/가로)
        /// 언어/지역 설정
        /// 다크모드/라이트모드
        /// 테스트용 launch argument / environment 주입
        /// 로그인 상태 초기화(로그아웃부터 시작 등)
        
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-SkipLogin"]
        app.launchEnvironment = ["mockNetwork": "true"]
        app.launch()

        // XCTAssertTrue(app.staticTexts["홈"].exists)
        // XCTAssertTrue(app.buttons["loginButton"].exists)
        
        // let homeText = app.staticTexts["홈"]
        // XCTAssertTrue(homeText.waitForExistence(timeout: 5), "홈 텍스트가 5초 안에 나타나지 않음")

        // let loginButton = app.buttons["loginButton"]
        // XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        
        // MARK: - 홈탭 존재 유무
        let homeTab = app.tabBars.buttons["홈"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5),"홈 탭이 존재하지 않음")
        
        // MARK: - 검색 버튼
        let searchButton = app.buttons["home_search_button"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        // MARK: - 검색 창
        let searchView = app.otherElements["search_root"]
        XCTAssertTrue(searchView.waitForExistence(timeout: 5))

    }

//    @MainActor
//    func testLaunchPerformance() throws {
//        // This measures how long it takes to launch your application.
//        measure(metrics: [XCTApplicationLaunchMetric()]) {
//            XCUIApplication().launch()
//        }
//    }
}
*/
