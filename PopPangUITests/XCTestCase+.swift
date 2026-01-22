//
//  XCTestCase+.swift
//  PopPangUITests
//
//  Created by 김동현 on 1/20/26.
//

import XCTest

extension XCTestCase {
    
    // 버튼 탭
    // - ex) tapButton(app: app, id: "home_search_button")
    func tapButton(app: XCUIApplication,
                   id: String,
                   timeout: TimeInterval = 5,
                   file: StaticString = #file,
                   line: UInt = #line
    ) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: timeout),
                      "버튼 없음: \(id)",
                      file: #file,
                      line: line)
        button.tap()
    }
    
    // 요소 탭
    // tapElement(app.buttons["home_search_button"])
    // tapElement(app.buttons["home_search_backbutton"])
    // tapElement(app.otherElements["home_search"])
    func tapElement(_ element: XCUIElement,
                    timeout: TimeInterval = 5,
                    message: String? = nil,
                    file: StaticString = #file,
                    line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            message ?? "요소 없음",
            file: file,
            line: line
        )
        element.tap()
    }
    
    // 텍스트필드 입력
    // - ex) typeText(app: app, id: "home_search_textfield", text: "팝업")
    func typeTextField(app: XCUIApplication,
                       id: String,
                       text: String,
                       timeout: TimeInterval = 5,
                       file: StaticString = #file,
                       line: UInt = #line
    ) {
        let textField = app.textFields[id]
        XCTAssertTrue(textField.waitForExistence(timeout: timeout),
                      "텍스트필드 없음: \(id)",
                      file: #file,
                      line: line)
        textField.tap()
        textField.typeText(text)
    }
    
    // 대기
    func sleep(seconds: TimeInterval) {
        let expectation = XCTestExpectation(description: "wait \(seconds) seconds")
        let result = XCTWaiter.wait(for: [expectation], timeout: seconds)
        XCTAssertEqual(result, .timedOut)
    }
    
    // 존재 확인
    func assertExists(_ element: XCUIElement,
                      timeout: TimeInterval = 5,
                      message: String,
                      file: StaticString = #file,
                      line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      message,
                      file: file,
                      line: line
        )
    }
    
    // 결과 개수
    func searchResultCount(
        app: XCUIApplication,
        id: String = "home_search_cell"
    ) -> Int {
        let results = app.otherElements.matching(identifier: id)
        let count = results.count
        print("🔍 검색 결과 개수:", count)
        return count
    }
    
    // 기본 뒤로가기 버튼
    func tapNavigationBackButton(app: XCUIApplication,
                                 timeout: TimeInterval = 5,
                                 file: StaticString = #file,
                                 line: UInt = #line
    ) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(
            backButton.waitForExistence(timeout: timeout),
            "네비게이션 뒤로가기 버튼 없음",
            file: file,
            line: line
        )
        backButton.tap()
    }
    
    // 화면 스크롤
    func scroll(app: XCUIApplication,
                direction: ScrollDirection,
                times: Int = 1) {
        for _ in 0..<times {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            case .left:
                app.swipeLeft()
            case .right:
                app.swipeRight()
            }
        }
    }

    enum ScrollDirection {
        case up, down, left, right
    }

    // 특정 요소가 보일 때까지 스크롤
    func scrollUntilVisibleAndTap(app: XCUIApplication,
                         element: XCUIElement,
                         maxScrolls: Int = 5,
                         file: StaticString = #file,
                         line: UInt = #line) {
        var attempts = 0

        while !element.exists && attempts < maxScrolls {
            app.swipeUp()
            attempts += 1
        }

        XCTAssertTrue(
            element.exists,
            "스크롤 후에도 요소를 찾을 수 없음",
            file: file,
            line: line
        )
        
        element.tap()
    }
}

