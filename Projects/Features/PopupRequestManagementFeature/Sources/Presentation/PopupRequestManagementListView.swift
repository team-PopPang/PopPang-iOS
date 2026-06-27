import ComposableArchitecture
import DSKit
import Domain
import SwiftUI

public struct PopupRequestManagementListView: View {
    let store: StoreOf<PopupRequestManagementListFeature>

    public init(store: StoreOf<PopupRequestManagementListFeature>) {
        self.store = store
    }

    public var body: some View {
        listContent
            .background(Color.mainGray4.ignoresSafeArea())
            .ppBackNavigationBar(
                title: "팝업 제보 관리",
                showsSeparator: true,
                onBack: {
                    store.send(.backTapped)
                }
            ) {
                refreshButton
            }
            .task {
                store.send(.onAppear)
            }
    }
}

private extension PopupRequestManagementListView {
    var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summarySection
                filterSection
                listSection
            }
            .padding(.horizontal, .contentPadding)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .refreshable {
            store.send(.refresh)
        }
    }

    var refreshButton: some View {
        Button {
            store.send(.refresh)
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.subBlack)
                .frame(width: 38, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(store.isLoading)
        .opacity(store.isLoading ? 0.4 : 1)
    }

    var summarySection: some View {
        HStack(spacing: 8) {
            PopupRequestSummaryTile(title: "대기", count: store.pendingCount)
            PopupRequestSummaryTile(title: "승인", count: store.approvedCount)
            PopupRequestSummaryTile(title: "반려", count: store.rejectedCount)
        }
    }

    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PopupRequestManagementFilter.allCases, id: \.self) { filter in
                    PopupRequestFilterChip(
                        title: filter.title,
                        isSelected: store.selectedFilter == filter
                    ) {
                        store.send(.filterSelected(filter))
                    }
                }
            }
        }
    }

    @ViewBuilder
    var listSection: some View {
        if store.isLoading, store.allItems.isEmpty {
            PopupRequestManagementLoadingView()
        } else if let errorMessage = store.errorMessage {
            PopupRequestManagementErrorView(message: errorMessage) {
                store.send(.refresh)
            }
        } else if store.filteredItems.isEmpty {
            PopupRequestManagementEmptyView()
        } else {
            LazyVStack(spacing: 10) {
                ForEach(store.filteredItems) { item in
                    Button {
                        store.send(.submissionTapped(item.id))
                    } label: {
                        PopupRequestManagementCell(item: item)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}

private struct PopupRequestSummaryTile: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainGray)

            Text("\(count)")
                .font(.scdream(.bold, size: 20))
                .foregroundStyle(Color.mainBlack)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .frame(height: 72)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(isSelected ? Color.subWhite : Color.mainGray)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isSelected ? Color.mainOrange : Color.subWhite)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.mainOrange : Color.mainGray3, lineWidth: 1)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct PopupRequestManagementCell: View {
    let item: PopupRequestManagementListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(2)

                    Text(item.roadAddress)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                PopupRequestStatusBadge(status: item.status)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.mainGray2)
                    .frame(width: 16, height: 28)
            }

            HStack(spacing: 8) {
                PopupRequestCellMetaText(text: item.region)
                PopupRequestCellDivider()
                PopupRequestCellMetaText(text: item.submitterNickname)
                PopupRequestCellDivider()
                PopupRequestCellMetaText(text: item.submittedAtText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestStatusBadge: View {
    let status: PopupSubmissionStatus

    var body: some View {
        Text(title)
            .font(.scdream(.medium, size: 11))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var title: String {
        switch status {
        case .pending:
            "검토 대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            Color.mainOrange
        case .approved:
            Color.mainGreen
        case .rejected:
            Color.mainRed
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            Color.categoryOrange
        case .approved:
            Color.mainGreen.opacity(0.12)
        case .rejected:
            Color.mainRed.opacity(0.12)
        }
    }
}

private struct PopupRequestCellMetaText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.scdream(.medium, size: 11))
            .foregroundStyle(Color.mainGray2)
            .lineLimit(1)
    }
}

private struct PopupRequestCellDivider: View {
    var body: some View {
        Circle()
            .fill(Color.mainGray3)
            .frame(width: 3, height: 3)
    }
}

private struct PopupRequestManagementLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.mainOrange)

            Text("팝업 제보를 불러오는 중입니다.")
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestManagementErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(Color.mainOrange)

            Text(message)
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
                .multilineTextAlignment(.center)

            MainOrangeButton(buttonTitle: "다시 시도", height: 44) {
                retry()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestManagementEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(Color.mainGray2)

            Text("표시할 팝업 제보가 없습니다.")
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
