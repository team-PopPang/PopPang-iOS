import ComposableArchitecture
import DSKit
import SwiftUI

struct PopupPaginationDemoView: View {
    @Bindable var store: StoreOf<PopupPaginationDemoFeature>

    var body: some View {
        ZStack {
            Color.subWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                statusBar
                content
            }
        }
        .task {
            store.send(.task)
        }
    }
}

private extension PopupPaginationDemoView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CURSOR LAB")
                .font(.scdream(.bold, size: 12))
                .tracking(2.4)
                .foregroundStyle(Color.mainOrange)

            Text("팝업 페이지네이션")
                .font(.scdream(.black, size: 26))
                .foregroundStyle(Color.mainBlack)

            Text("운영 API의 cursor 흐름만 독립적으로 확인합니다.")
                .font(.scdream(.regular, size: 13))
                .foregroundStyle(Color.mainGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    var statusBar: some View {
        HStack(spacing: 8) {
            statusPill(title: "PAGE", value: "\(store.loadedPageCount)")
            statusPill(title: "ITEM", value: "\(store.items.count)")
            statusPill(
                title: "CURSOR",
                value: store.nextCursor.map(String.init) ?? "nil"
            )

            Spacer(minLength: 0)

            Circle()
                .fill(
                    store.hasStarted && store.hasNext
                        ? Color.mainOrange
                        : Color.mainGray
                )
                .frame(width: 7, height: 7)

            Text(paginationStatusText)
                .font(.scdream(.regular, size: 11))
                .foregroundStyle(Color.mainGray)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    var content: some View {
        if store.isInitialLoading {
            loadingState
        } else if !store.hasStarted {
            emptyState(
                title: "데모 UUID를 확인해 주세요",
                description: "AlertFeatureDemo.xcconfig의 UUID가 비어 있습니다."
            )
        } else if store.items.isEmpty, let errorMessage = store.errorMessage {
            errorState(message: errorMessage)
        } else if store.items.isEmpty {
            emptyState(
                title: "표시할 팝업이 없습니다",
                description: "API 응답의 items가 비어 있습니다."
            )
        } else {
            popupList
        }
    }

    var popupList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.items) { item in
                    PopupPaginationCard(item: item)
                        .task(id: item.id) {
                            guard item.id == store.items.last?.id else { return }
                            store.send(.reachedEnd)
                        }
                }

                listFooter
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    var listFooter: some View {
        if store.isLoadingNextPage {
            HStack(spacing: 10) {
                ProgressView()
                Text("다음 페이지를 불러오는 중")
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray)
            }
            .padding(.vertical, 20)
        } else if let errorMessage = store.errorMessage {
            VStack(spacing: 10) {
                Text(errorMessage)
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .multilineTextAlignment(.center)

                if store.hasNext {
                    Button("다시 시도") {
                        store.send(.retryTapped)
                    }
                    .font(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainOrange)
                }
            }
            .padding(.vertical, 20)
        } else if !store.hasNext {
            Text("모든 팝업을 불러왔습니다")
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainGray)
                .padding(.vertical, 20)
        }
    }

    var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("첫 페이지를 불러오는 중")
                .font(.scdream(.regular, size: 13))
                .foregroundStyle(Color.mainGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func emptyState(title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color.mainOrange)

            Text(title)
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Text(description)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 36)
    }

    func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color.mainRed)

            Text(message)
                .font(.scdream(.regular, size: 13))
                .foregroundStyle(Color.mainRed)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .font(.scdream(.bold, size: 13))
            .foregroundStyle(Color.mainOrange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 36)
    }

    func statusPill(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.mainGray)

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(Color.white)
        .clipShape(Capsule())
    }

    var paginationStatusText: String {
        guard store.hasStarted else { return "대기 중" }
        return store.hasNext ? "다음 페이지 있음" : "마지막 페이지"
    }
}

private struct PopupPaginationCard: View {
    let item: PopupPaginationItem

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: item.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color.mainGray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 102, height: 126)
            .background(Color.mainGray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(item.region)
                        .font(.scdream(.bold, size: 11))
                        .foregroundStyle(Color.mainOrange)

                    Spacer()

                    Image(systemName: item.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            item.isFavorited ? Color.mainOrange : Color.mainGray
                        )
                }

                Text(item.name)
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.mainBlack)
                    .lineLimit(2)
                    .padding(.top, 8)

                Spacer()

                Text("\(item.startDate) - \(item.endDate)")
                    .font(.scdream(.regular, size: 11))
                    .foregroundStyle(Color.mainGray)
                    .lineLimit(1)

                Text(item.popupUuid)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.mainGray.opacity(0.7))
                    .lineLimit(1)
                    .padding(.top, 5)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mainGray.opacity(0.12), lineWidth: 1)
        }
    }
}
