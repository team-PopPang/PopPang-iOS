import ComposableArchitecture
import DSKit
import PopupSubmissionFormFeature
import SwiftUI

public struct PopupRequestManagementDetailView: View {
    let store: StoreOf<PopupRequestManagementDetailFeature>

    public init(store: StoreOf<PopupRequestManagementDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        detailContent
            .background(Color.mainGray4.ignoresSafeArea())
            .ppBackNavigationBar(
                title: "제보 상세",
                showsSeparator: true,
                onBack: {
                    store.send(.delegate(.pop))
                }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionButtons
            }
            .task {
                store.send(.onAppear)
            }
            .alert("처리 실패", isPresented: errorPresentedBinding) {
                Button("확인") {
                    store.send(.errorAlertDismissed)
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .alert("처리 완료", isPresented: completionPresentedBinding) {
                Button("확인") {
                    store.send(.completionAlertDismissed)
                }
            } message: {
                Text(store.resultPopupUuid == nil ? "제보가 반려되었습니다." : "팝업 리스트에 반영되었습니다.")
            }
    }
}

private extension PopupRequestManagementDetailView {
    @ViewBuilder
    var detailContent: some View {
        if store.isLoading && store.form.name.isEmpty && store.originalDescription.isEmpty {
            ScrollView {
                ProgressView()
                    .tint(Color.mainOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusSection
                    originalDescriptionSection
                    PopupSubmissionFormView(store: store.scope(state: \.form, action: \.form))
                }
                .padding(.horizontal, .contentPadding)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }
            .refreshable {
                store.send(.refresh)
            }
        }
    }

    var statusSection: some View {
        HStack {
            Text(statusTitle)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainOrange)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.categoryOrange)
                .clipShape(Capsule())

            Spacer()
        }
    }

    var originalDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("원본 제보 내용")
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Text(store.originalDescription.isEmpty ? "제보 내용이 없습니다." : store.originalDescription)
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

    var actionButtons: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                Button {
                    store.send(.rejectTapped)
                } label: {
                    Text(store.isSubmitting ? "처리 중" : "반려")
                        .font(.scdream(.medium, size: 15))
                        .foregroundStyle(Color.mainRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mainRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(store.isSubmitting)

                MainOrangeButton(
                    buttonTitle: store.isSubmitting ? "처리 중" : "승인",
                    height: 56
                ) {
                    store.send(.approveTapped)
                }
                .disabled(store.isSubmitting)
                .opacity(store.isSubmitting ? 0.45 : 1)
            }
            .padding(.horizontal, .contentPadding)
            .padding(.vertical, 12)
            .background(Color.subWhite)
        }
    }

    var errorPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    store.send(.errorAlertDismissed)
                }
            }
        )
    }

    var completionPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.isCompleted },
            set: { isPresented in
                if isPresented == false {
                    store.send(.completionAlertDismissed)
                }
            }
        )
    }

    var statusTitle: String {
        switch store.status {
        case .pending:
            "검토 대기"
        case .approved:
            "승인"
        case .rejected:
            "반려"
        }
    }
}
