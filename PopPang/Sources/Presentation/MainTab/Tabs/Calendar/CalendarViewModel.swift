//
//  CalendarViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import Foundation

final class CalendarViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    
    // 서버에서 가져온 전체 팝업 리스트
    @Published var calendarPopups: [Popup] = []
    
    // 현재 선택된 날짜
    @Published var selectedDate: Date = Date()
    
    // 현재 선택된 날짜에 해당하는 팝업 목록
    @Published var selectedPopups: [Popup] = []
    
    // 날짜별 팝업 개수(캘린더 숫자 하단 표시용)
    @Published var popupEventCounts: [Date: Int] = [:]
    
    init(userUuid: String) {
        self.userUuid = userUuid
        loadPopups()
    }
}

extension CalendarViewModel {
    
    /// 서버에서 팝업 리스트 비동기 호출, 완료 후 날짜별 이벤트 개수 계산
    private func loadPopups() {
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.calendarPopups = popups
                    self.calculateEventCounts()
                    self.selectDate(self.selectedDate)
                }
            } catch {
                print("❌ getPopupList Error: \(error)")
            }
        }
    }
    
    
    /// 팝업의 시작일~종료일을 순회하며 날짜별 이벤트 개수 집계하여 popupEventCounts에 저장
    /// - 팝업 기간이 10/15 ~ 10/17 이라면
    ///   - 10/15 → 1건
    ///   - 10/16 → 1건
    ///   - 10/17 → 1건
    private func calculateEventCounts() {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for popup in calendarPopups {
            var date = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)
            
            // 시작일부터 종료일까지 하루씩 순회하며 개수 증가
            while date <= end {
                counts[date, default: 0] += 1
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
        
        popupEventCounts = counts
    }
    
    
    /// 사용자가 캘린더에서 특정 날짜를 선택하면 호출
    /// 선택된 날짜를 selectedData로 업데이트
    /// 현재 날짜에 포함되는 팝업들을 필터링 하여 selectedPopups에 저장
    /// - Parameter date: 사용자가 선택한 날짜
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedPopups = calendarPopups.filter {
            isDate(date, between: $0.startDate, and: $0.endDate)
        }
    }
    
    
    /// 주어진 날짜가 특정 팝업의 시작일과 종료일 사이에 포함되는지 확인
    /// - Parameters:
    ///   - date: 검사할 대상 날짜
    ///   - start: 팝업 시작일
    ///   - end: 팝업 종료일
    /// - Returns: 날짜가 시작일과 종료일 사이에 포함되면 true, 아니면 false
    private func isDate(_ date: Date, between start: Date, and end: Date) -> Bool {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        let t = cal.startOfDay(for: date)
        return t >= s && t <= e
    }
}
