import ComposableArchitecture
import Domain
import DSKit
import SwiftUI

public struct AuthFeatureView: View {
    let store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            DSKitResource.image("Logo Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)

            VStack {
                SocialLoginButton(type: .kakao) {
                    store.send(.loginTapped(.kakao))
                }
                .disabled(store.isSubmitting)

                SocialLoginButton(type: .apple) {
                    store.send(.loginTapped(.apple))
                }
                .disabled(store.isSubmitting)

                SocialLoginButton(type: .google) {
                    store.send(.loginTapped(.google))
                }
                .disabled(store.isSubmitting)
            }
            .padding(.top, 120)
        }
        .padding(.horizontal, 24)
        .alert(
            Text("로그인할 수 없어요", bundle: .module),
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { store.send(.errorDismissed) }
                }
            )
        ) {
            Button(String(localized: "확인", bundle: .module), role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
