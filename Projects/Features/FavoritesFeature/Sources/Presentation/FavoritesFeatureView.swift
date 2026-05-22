import SwiftUI

public struct FavoritesFeatureView: View {
    @Environment(FavoritesFeatureCoordinator.self) private var coordinator
    @State private var selectedMode: FavoriteMode = .list

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("찜")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Button("알림센터") {
                    coordinator.push(.alert)
                }
                .buttonStyle(.bordered)
            }

            Picker("모드", selection: $selectedMode) {
                ForEach(FavoriteMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(selectedMode.items, id: \.title) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.description)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
        .padding()
    }
}

private enum FavoriteMode: CaseIterable {
    case list
    case calendar

    var title: String {
        switch self {
        case .list:
            "리스트"
        case .calendar:
            "캘린더"
        }
    }

    var items: [(title: String, description: String)] {
        switch self {
        case .list:
            [
                ("성수 라이프스타일 팝업", "리스트 기반 찜 보기 화면 이식 대상"),
                ("한남 리빙 브랜드 팝업", "팝업 상세와 동일한 찜 상태 공유 필요"),
            ]
        case .calendar:
            [
                ("5월 4주차", "찜한 팝업 일정을 달력 셀과 연결"),
                ("6월 1주차", "V0 FavoriteCalendarView 흐름 이식 대상"),
            ]
        }
    }
}
