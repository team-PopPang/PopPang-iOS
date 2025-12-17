//
//  PerformanceTest.swift
//  RepositoryTest
//
//  Created by 김동현 on 11/30/25.
//

//import Testing
//@testable import PopPang
//import Foundation
//
//@Test
//func testRepositoryPerformance() async throws {
//    let repository = PopupRepositoryImpl()
//    
//    let start = CFAbsoluteTimeGetCurrent()
//
//    let list = try await repository.getPersonalPopupList(
//        userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13"
//    )
//
//    let end = CFAbsoluteTimeGetCurrent()
//    let duration = end - start
//    
//    #expect(!list.isEmpty)
//    print("⏱ API Time:", duration, "seconds")
//}

import XCTest
@testable import PopPang

final class PerformanceTest: XCTestCase {
    
    private var popupRepository: PopupRepositoryProtocol!

    override func setUp() {
        super.setUp()
        popupRepository = PopupRepositoryImpl()
    }
    
    func testRepositoryPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "repo")

            Task {
                do {
                    let list = try await self.popupRepository.getPersonalPopupList(
                        userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13"
                    )
                    XCTAssertFalse(list.isEmpty)
                    expectation.fulfill()
                } catch {
                    XCTFail("Error: \(error)")
                }
            }

            wait(for: [expectation], timeout: 5)
        }
    }
}

// MARK: - 1) 순차(Sequential) API 성능 측정
// Time: 0.113 sec
extension PerformanceTest {
    func testSequentialAPI() {
        measure {
            let ex = XCTestExpectation(description: "sequential")
            
            Task {
                do {
                    let uuid = "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13"
                    
                    // 순차 호출
                    let list1 = try await popupRepository.getPersonalRandomPopupList(userUuid: uuid)
                    let list2 = try await popupRepository.getPersonalUpcomingPopupList(userUuid: uuid)
                    let list3 = try await popupRepository.getPersonalRandomPopupList(userUuid: uuid)
                    
                    XCTAssertFalse(list1.isEmpty)
                    XCTAssertFalse(list2.isEmpty)
                    XCTAssertFalse(list3.isEmpty)
                    
                    ex.fulfill()
                } catch {
                    XCTFail("Error: \(error)")
                }
            }
            
            wait(for: [ex], timeout: 10)
        }
    }
}

// MARK: - 2) 동시(Concurrent) API 성능 측정
// Time: 0.048 sec
extension PerformanceTest {
    func testConcurrentAPI() {
        measure {
            let ex = XCTestExpectation(description: "concurrent")
            
            Task {
                do {
                    let uuid = "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13"
                    
                    // 병렬 호출
                    let results = try await withThrowingTaskGroup(of: [PopupDTO].self) { group in
                        
                        group.addTask { try await self.popupRepository.getPersonalRandomPopupList(userUuid: uuid) }
                        group.addTask { try await self.popupRepository.getPersonalUpcomingPopupList(userUuid: uuid) }
                        group.addTask { try await self.popupRepository.getPersonalRandomPopupList(userUuid: uuid) }

                        var combined: [[PopupDTO]] = []
                        
                        for try await result in group {
                            combined.append(result)
                        }
                        
                        return combined.flatMap { $0 }
                    }
                    
                    XCTAssertFalse(results.isEmpty)
                    ex.fulfill()
                    
                } catch {
                    XCTFail("Error: \(error)")
                }
            }
            
            wait(for: [ex], timeout: 10)
        }
    }
}
