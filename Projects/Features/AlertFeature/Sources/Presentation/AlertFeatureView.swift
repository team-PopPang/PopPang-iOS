import SwiftUI

public struct AlertFeatureView: View {
    @State private var selectedTab: AlertTab = .activity
    @State private var isEditing = false
    @State private var activityItems = AlertActivityItem.mock
    @State private var selectedKeywords = Set(["패션", "전시"])

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Picker("알림", selection: $selectedTab) {
                ForEach(AlertTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            if selectedTab == .activity {
                List {
                    Section {
                        Toggle(isEditing ? "편집 종료" : "편집 모드", isOn: $isEditing)
                    }

                    Section("활동 알림") {
                        ForEach(activityItems) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(item.isUnread ? Color.orange : Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                    Text(item.message)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(item.date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if isEditing {
                                    Button(role: .destructive) {
                                        activityItems.removeAll { $0.id == item.id }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("키워드 알림을 켜 두면 V0처럼 등록/오픈 소식을 빠르게 확인할 수 있습니다.")
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 10) {
                            ForEach(keywordOptions, id: \.self) { keyword in
                                Button(keyword) {
                                    if selectedKeywords.contains(keyword) {
                                        selectedKeywords.remove(keyword)
                                    } else {
                                        selectedKeywords.insert(keyword)
                                    }
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selectedKeywords.contains(keyword) ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(selectedKeywords.contains(keyword) ? Color.orange : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("알림")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectedTab == .activity {
                    Button(isEditing ? "완료" : "편집") {
                        isEditing.toggle()
                    }
                }
            }
        }
    }
}

private enum AlertTab: CaseIterable {
    case activity
    case keywords

    var title: String {
        switch self {
        case .activity:
            "활동"
        case .keywords:
            "키워드 설정"
        }
    }
}

private struct AlertActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: String
    let isUnread: Bool

    static let mock: [AlertActivityItem] = [
        .init(title: "찜한 팝업이 곧 종료돼요", message: "성수 브랜드 쇼룸이 2일 뒤 종료됩니다.", date: "오늘", isUnread: true),
        .init(title: "새 팝업이 등록됐어요", message: "전시 키워드에 맞는 새로운 팝업이 오픈했습니다.", date: "어제", isUnread: true),
        .init(title: "리뷰 반응이 도착했어요", message: "내가 본 팝업에 새 리뷰가 3개 등록됐습니다.", date: "5월 20일", isUnread: false),
    ]
}

private extension AlertFeatureView {
    var keywordOptions: [String] {
        ["패션", "전시", "캐릭터", "뷰티", "푸드", "라이프", "한정굿즈", "포토존"]
    }
}
