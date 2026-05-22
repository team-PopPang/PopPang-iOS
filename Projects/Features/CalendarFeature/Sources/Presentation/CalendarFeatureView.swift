import SwiftUI

public struct CalendarFeatureView: View {
    public init() {}

    public var body: some View {
        List {
            Section("다가오는 일정") {
                ForEach(mockSchedules, id: \.title) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private extension CalendarFeatureView {
    var mockSchedules: [(title: String, date: String, note: String)] {
        [
            ("더현대 서울 아트 팝업", "5월 24일 토요일", "찜한 팝업의 종료 2일 전 알림 예정"),
            ("성수 디저트 팝업", "5월 27일 화요일", "오픈 첫날 방문 후보"),
            ("홍대 브랜드 협업 팝업", "6월 1일 일요일", "지도 탭에서 길찾기 연결 예정"),
        ]
    }
}
