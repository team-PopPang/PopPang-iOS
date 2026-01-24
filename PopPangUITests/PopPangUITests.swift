//
//  PopPangUITests.swift
//  PopPangUITests
//
//  Created by 김동현 on 1/16/26.
//

import XCTest

final class PopPangUITests: XCTestCase {

    // MARK: - 이 클래스 안의 각 테스트 메서드 실행 직전마다 호출
    /// testExample() 실행 전 1번
    /// testLaunchPerformance() 실행 전 1번
    /// throws?
    /// - 준비 과정에서 실패할 수 있기 때문
    /// - 예: 테스트 계정 세팅 실패, 초기 상태 구성 실패 등
    /// - → throw 하면 해당 테스트를 실패로 처리하고 종료 가능.
    override func setUpWithError() throws {

        /// true면: assert 실패해도 계속 다음 줄 실행
        /// false면: assert 실패하면 그 테스트를 즉시 중단
        continueAfterFailure = false
    }

    // MARK: - 테스트 후 정리
    /// 각 테스트 메서드가 끝난 직후마다 호출됨
    /// - 테스트가 만든 상태를 정리
    /// - 로그아웃
    /// - 테스트 데이터 삭제(가능하면)
    /// - 메모리 누수 확인 도구 등을 붙일 때도 씀
    override func tearDownWithError() throws {

    }
}

extension XCTestCase {
    // UI tests must launch the application that they test.
    /// 화면 회전 고정(세로/가로)
    /// 언어/지역 설정
    /// 다크모드/라이트모드
    /// 테스트용 launch argument / environment 주입
    /// 로그인 상태 초기화(로그아웃부터 시작 등)
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-SkipLogin"]
        app.launchEnvironment = ["mockNetwork": "true"]
        app.launch()
        return app
    }
}

extension PopPangUITests {
    @MainActor
    func testHome() throws {
        
        let app = launchApp()
        
        // 홈 탭 존재
        let homeTab = app.tabBars.buttons["홈"]
        assertExists(homeTab, message: "홈 탭이 존재하지 않음")
        
        // 검색 버튼 탭
        tapButton(app: app, id: "home_search_button")

        // 검색 화면 확인
        assertExists(app.otherElements["home_search"], message: "검색 화면 없음")
        
        // 5초 대기
        sleep(seconds: 5)

        // 검색어 입력
        typeTextField(app: app, id: "home_search_textfield", text: "팝업")
        
        // 5초 대기
        sleep(seconds: 5)
        
        // 검색 결과가 1개 이상인지
        XCTAssertTrue(searchResultCount(app: app) > 0, "검색 결과 없음")
        
        // 뒤로가기 버튼 탭
        tapButton(app: app, id: "home_search_backbutton")
        
        // 홈 화면으로 복귀했는지 확인
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "뒤로가기 후 홈 화면으로 돌아오지 않음")
        
        // 오픈 예정 팝업 버튼 탭
        tapButton(app: app, id: "home_comming_button")
        
        // 검색 결과가 1개 이상인지
        XCTAssertTrue(searchResultCount(app: app, id: "home_comming_cell") > 0, "검색 결과 없음")
        
        // 뒤로가기 버튼 탭
        tapNavigationBackButton(app: app)
        
        // 드롭다운 버튼
        let regionButton = app.buttons["home_region_dropdown"]
        let sortButton = app.buttons["home_sort_dropdown"]
        
        scrollUntilVisibleAndTap(
                app: app,
                element: regionButton
            )
        
        tapButton(app: app, id: "home_region_서울")
        tapButton(app: app, id: "home_district_전체")

        scrollUntilVisibleAndTap(
            app: app,
            element: sortButton
        )
        
        tapButton(app: app, id: "home_sort_option_MOST_VIEWED")
        
    }
    
    /*
    @MainActor
    func testHome2() throws {
        
        let app = XCUIApplication()
        app.launchArguments = ["-UITestMode", "-SkipLogin"]
        app.launchEnvironment = ["mockNetwork": "true"]
        app.launch()
        
        // MARK: - 홈탭 존재 유무
        let homeTab = app.tabBars.buttons["홈"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5),"홈 탭이 존재하지 않음")
        
        // MARK: - 검색 버튼
        let searchButton = app.buttons["home_search_button"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        // MARK: - 검색 창 띄우기
        let searchView = app.otherElements["home_search"]
        XCTAssertTrue(searchView.waitForExistence(timeout: 5))

        // MARK: - 검색 텍스트 필드 터치
        let searchTextField = app.textFields["home_search_textfield"]
        // searchTextField.exists // 바로 체크는 지양
        XCTAssertTrue(searchTextField.waitForExistence(timeout: 5))
        searchTextField.tap()
        searchTextField.typeText("팝업")
        
        // MARK: - 2초 대기
        let expectation = XCTestExpectation(description: "Wait after typing")
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(result, .timedOut)
        
        // MARK: - 검색 결과가 1개 이상인지
        let results = app.otherElements.matching(identifier: "home_search_cell")
        XCTAssertTrue(results.count > 0, "검색 결과 없음")
        print("🔍 검색 결과 개수:", results.count)
        
        // MARK: - 뒤로가기 버튼 탭
        let backButton = app.buttons["home_search_backbutton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "뒤로가기 버튼 없음")
        backButton.tap()
        
        // MARK: - 홈 화면으로 복귀했는지 확인
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "뒤로가기 후 홈 화면으로 돌아오지 않음")
    }
     */
}

