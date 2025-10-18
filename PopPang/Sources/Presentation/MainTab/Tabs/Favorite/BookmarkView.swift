//
//  BookmarkView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import Kingfisher

struct BookmarkView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var bookmarkViewModel: BookmarkViewModel
    private let segments: [String] = ["찜리스트", "찜캘린더"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바            
            CustomNavigationBar {
                Text("찜")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                    .frame(height: 45)
                
                Spacer()
                
                IconButton {
                    print("알림 버튼 클릭됨")
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            // MARK: - 세그먼트
            SegmentedControlView(segments: segments,
                                 views: [
                                    FavoriteListView(),
                                    FavoriteCalendarView()
                                ],
                                 background: .mainGray3,
                                 foreground: .mainOrange,
            )
            Spacer()
        }
    }
}

final class BookmarkViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var likePostIds: Set<String> = [] // 찜 목록 popupUuid
    
    // 서버에서 가져온 찜 팝업 리스트
    @Published var favoritePopups: [Popup] = [.popupMock, .popupMock2, .popupMock3]
    
    // 캘린더 에서 클릭된 찜 팝업 리스트
    @Published var todayPopups: [Popup] = []
    
    // 현재 선택된 날짜
    @Published var selectedDate: Date = Date()
    
    // 현재 선택된 날짜에 해당하는 팝업 목록
    @Published var popupEventCounts: [Date: Int] = [:]
    
    // MARK: - 캘린더 관련 추가 예정
    init(userUuid: String) {
        self.userUuid = userUuid
        
        Task {
            await loadFavoritePopups()
        }
    }
}

// MARK: - 팝업 load 및 캘린더 관련 메서드
extension BookmarkViewModel {
    
    /// 서버에서 찜 팝업 리스트 비동기 호출, 완료 후 날짜별 이벤트 개수 계산
    func loadFavoritePopups() async {
        do {
            let favoritePopups = try await popupUsecase.getFavoriteList(userUuid: userUuid)
            await MainActor.run {
                self.favoritePopups = favoritePopups
                self.calculateEventCounts()
                self.selectDate(self.selectedDate)
                self.likePostIds = Set(favoritePopups.map { $0.popupUuid })
            }
        } catch {
            print("❌ BookmarkViewModel.loadFavoritePopups 에러: \(error)")
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
        
        for popup in favoritePopups {
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
    
    
    /// 사용자가 캘린더에서 특정 날짜를 선택하면 호출
    /// 선택된 날짜를 selectedData로 업데이트
    /// 현재 날짜에 포함되는 팝업들을 필터링 하여 selectedPopups에 저장
    /// - Parameter date: 사용자가 선택한 날짜
    func selectDate(_ date: Date) {
        selectedDate = date
        todayPopups = favoritePopups.filter {
            isDate(date, between: $0.startDate, and: $0.endDate)
        }
    }
}

// MARK: - 찜 누르기 관련 메서드
extension BookmarkViewModel {
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        likePostIds.contains(popup.popupUuid)
    }
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) async {
        
        do {
            if likePostIds.contains(popup.popupUuid) {
                print("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.remove(popup.popupUuid)
                }
                await loadFavoritePopups()
            } else {
                print("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.insert(popup.popupUuid)
                }
            }
        } catch {
            print("❌ 찜 토글 실패:", error)
        }
    }
    
}

#Preview {
    NavigationStack {
        BookmarkView()
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
            .environmentObject(RootViewModel())
            .environmentObject(BookmarkViewModel(userUuid: "1234"))
    }
}




