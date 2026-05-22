import SwiftUI

public struct SearchFeatureView: View {
    @State private var query = ""

    public init() {}

    public var body: some View {
        List {
            Section {
                TextField("지역, 브랜드, 키워드를 검색", text: $query)
                    .textInputAutocapitalization(.never)
            }

            Section("추천 결과") {
                ForEach(mockResults.filter(matchesQuery), id: \.title) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func matchesQuery(_ item: (title: String, subtitle: String)) -> Bool {
        guard query.isEmpty == false else { return true }
        return item.title.localizedCaseInsensitiveContains(query) || item.subtitle.localizedCaseInsensitiveContains(query)
    }
}

private extension SearchFeatureView {
    var mockResults: [(title: String, subtitle: String)] {
        [
            ("성수 편집숍 팝업", "성수역 도보 5분"),
            ("잠실 캐릭터 스토어", "잠실 롯데월드몰"),
            ("홍대 전시형 팝업", "홍대입구역 인근"),
        ]
    }
}
