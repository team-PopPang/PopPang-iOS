import ComposableArchitecture
import DSKit
import PopupSubmissionFormFeature
import SwiftUI

public struct PopupRequestFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    let store: StoreOf<PopupRequestFeature>

    public init(store: StoreOf<PopupRequestFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                PopupSubmissionFormView(
                    store: store.scope(state: \.form, action: \.form)
                )
                .padding(.horizontal, .contentPadding)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .background(Color.mainGray4.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            ModalNavigationHeader(
                title: "팝업 제보하기",
                showsSeparator: true,
                onBack: close
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            submitButton
        }
        .task {
            store.send(.onAppear)
        }
        .alert("제출 실패", isPresented: errorPresentedBinding) {
            Button("확인") {
                store.send(.errorAlertDismissed)
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .alert("제보 완료", isPresented: successPresentedBinding) {
            Button("확인") {
                store.send(.successAlertDismissed)
                dismiss()
            }
        } message: {
            Text("팝업 제보가 등록되었습니다.")
        }
    }
}

private extension PopupRequestFeatureView {
    var submitButton: some View {
        VStack(spacing: 0) {
            Divider()

            MainOrangeButton(
                buttonTitle: store.isSubmitting ? "제출 중" : "제보하기",
                height: 56
            ) {
                store.send(.submitButtonTapped)
            }
            .disabled(store.isSubmitting)
            .opacity(store.isSubmitting ? 0.45 : 1)
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

    var successPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.isSubmitted },
            set: { isPresented in
                if isPresented == false {
                    store.send(.successAlertDismissed)
                }
            }
        )
    }

    func close() {
        store.send(.dismissTapped)
        dismiss()
    }
}

#if DEBUG
#Preview("PopupRequestFeatureView") {
    PopupRequestFeatureView(
        store: Store(
            initialState: PopupRequestFeature.State(userUuid: "preview-user")
        ) {
            PopupRequestFeature()
        } withDependencies: {
            $0.popupRequestClient = .previewValue
        }
    )
}
#endif
