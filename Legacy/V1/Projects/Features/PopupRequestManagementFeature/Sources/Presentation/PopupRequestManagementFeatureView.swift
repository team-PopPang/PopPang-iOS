import Compound
import DSKit
import SwiftUI

public struct PopupRequestManagementFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var compound: PopupRequestManagementFeatureCompound

    private let onBack: (() -> Void)?
    private let onSelectSubmission: (String) -> Void

    public init(
        items: [PopupRequestManagementItem] = [],
        onBack: (() -> Void)? = nil,
        onSelectSubmission: @escaping (String) -> Void = { _ in }
    ) {
        _compound = State(wrappedValue: PopupRequestManagementFeatureCompound(items: items))
        self.onBack = onBack
        self.onSelectSubmission = onSelectSubmission
    }

    public var body: some View {
        listContent
            .background(Color.mainGray4.ignoresSafeArea())
            .ppBackNavigationBar(
                title: "팝업 제보 관리",
                showsSeparator: true,
                onBack: close
            ) {
                refreshButton
            }
            .compoundOnLoad(compound, .onAppear)
    }
}

private extension PopupRequestManagementFeatureView {
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
            compound.send(.refresh)
        }
    }

    var refreshButton: some View {
        Button {
            compound.send(.refresh)
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.subBlack)
                .frame(width: 38, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(compound.state.isLoading)
        .opacity(compound.state.isLoading ? 0.4 : 1)
    }

    func close() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    var summarySection: some View {
        HStack(spacing: 8) {
            PopupRequestSummaryTile(title: "대기", count: compound.state.pendingCount)
            PopupRequestSummaryTile(title: "승인", count: compound.state.approvedCount)
            PopupRequestSummaryTile(title: "반려", count: compound.state.rejectedCount)
        }
    }

    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PopupRequestManagementFilter.allCases, id: \.self) { filter in
                    PopupRequestFilterChip(
                        title: filter.title,
                        isSelected: compound.state.selectedFilter == filter
                    ) {
                        compound.send(.filterSelected(filter))
                    }
                }
            }
        }
    }

    @ViewBuilder
    var listSection: some View {
        if compound.state.isLoading, compound.state.items.isEmpty {
            PopupRequestManagementLoadingView()
        } else if let errorMessage = compound.state.errorMessage {
            PopupRequestManagementErrorView(message: errorMessage) {
                compound.send(.refresh)
            }
        } else if compound.state.filteredItems.isEmpty {
            PopupRequestManagementEmptyView()
        } else {
            LazyVStack(spacing: 10) {
                ForEach(compound.state.filteredItems) { item in
                    PopupRequestManagementCell(item: item) {
                        onSelectSubmission(item.id)
                    }
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
    let item: PopupRequestManagementItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.popupName)
                            .font(.scdream(.bold, size: 15))
                            .foregroundStyle(Color.mainBlack)
                            .lineLimit(2)

                        Text(item.address)
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
        .buttonStyle(PressableButtonStyle())
    }
}

public struct PopupRequestManagementDetailFeatureView: View {
    @State private var compound: PopupRequestManagementDetailFeatureCompound

    private let onBack: () -> Void

    public init(
        submissionId: String,
        onBack: @escaping () -> Void
    ) {
        _compound = State(wrappedValue: PopupRequestManagementDetailFeatureCompound(submissionId: submissionId))
        self.onBack = onBack
    }

    public var body: some View {
        detailContent
            .background(Color.mainGray4.ignoresSafeArea())
            .ppBackNavigationBar(
                title: "제보 상세",
                showsSeparator: true,
                onBack: onBack
            )
            .compoundOnLoad(compound, .onAppear)
    }

    @ViewBuilder
    private var detailContent: some View {
        if compound.state.isLoading, compound.state.item == nil {
            ScrollView {
                PopupRequestManagementLoadingView()
                    .padding(.horizontal, .contentPadding)
                    .padding(.top, 12)
            }
        } else if let errorMessage = compound.state.errorMessage {
            ScrollView {
                PopupRequestManagementErrorView(message: errorMessage) {
                    compound.send(.refresh)
                }
                .padding(.horizontal, .contentPadding)
                .padding(.top, 12)
            }
        } else if let item = compound.state.item {
            content(item: item)
        } else {
            ScrollView {
                PopupRequestManagementEmptyView()
                    .padding(.horizontal, .contentPadding)
                    .padding(.top, 12)
            }
        }
    }

    private func content(item: PopupRequestManagementItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerSection(item: item)
                infoSection(item: item)
                descriptionSection(item: item)
            }
            .padding(.horizontal, .contentPadding)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private func headerSection(item: PopupRequestManagementItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.popupName)
                    .font(.scdream(.bold, size: 20))
                    .foregroundStyle(Color.mainBlack)
                    .lineLimit(3)

                Spacer(minLength: 8)

                PopupRequestStatusBadge(status: item.status)
            }

            Text(item.address)
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
                .lineLimit(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func infoSection(item: PopupRequestManagementItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            PopupRequestDetailRow(title: "운영 기간", value: item.periodText)
            PopupRequestDetailRow(title: "지역", value: item.region)
            PopupRequestDetailRow(title: "제보자", value: item.submitterNickname)
            PopupRequestDetailRow(title: "제보일", value: item.submittedAtText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func descriptionSection(item: PopupRequestManagementItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("제보 내용")
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Text(item.description.isEmpty ? "제보 내용이 없습니다." : item.description)
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainGray2)
                .frame(width: 64, alignment: .leading)

            Text(value.isEmpty ? "-" : value)
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PopupRequestStatusBadge: View {
    let status: PopupRequestManagementStatus

    var body: some View {
        Text(status.title)
            .font(.scdream(.medium, size: 11))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(backgroundColor)
            .clipShape(Capsule())
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
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.mainOrange)

            Text(message)
                .font(.scdream(.medium, size: 13))
                .foregroundStyle(Color.mainGray)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button(action: retry) {
                Text("다시 불러오기")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.subWhite)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(Color.mainOrange)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .padding(.horizontal, 18)
        .background(Color.subWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PopupRequestManagementEmptyView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .regular))
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
