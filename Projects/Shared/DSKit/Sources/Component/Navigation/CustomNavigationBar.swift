import SwiftUI

/// 화면 내부에 직접 배치하는 PopPang 커스텀 내비게이션 바 컨테이너.
/// 홈, 캘린더, 찜, 마이페이지처럼 탭 루트 화면의 상단 헤더를 만들 때 사용한다.
/// 뒤로가기 버튼이 있는 push 서브 화면에는 `ppBackNavigationBar`를 사용한다.
public struct CustomNavigationBar<Content: View>: View {
    let content: Content
    let hPadding: CGFloat

    /// 지정한 좌우 패딩으로 내비게이션 바 높이와 상단 여백을 맞춘다.
    public init(
        hPadding: CGFloat = .contentPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.hPadding = hPadding
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 0) {
            content
        }
        .padding(.top, 10)
        .padding(.horizontal, hPadding)
        .frame(height: 55)
    }
}

/// 뒤로가기 버튼과 중앙 타이틀만 있는 SwiftUI 네이티브 내비게이션 바 modifier.
/// 탭 루트 헤더용 `CustomNavigationBar`와 달리 push 서브 화면 전용이다.
/// `showsSeparator`가 true이면 내비게이션 바 아래 구분선을 표시한다.
private struct BackNavigationBarModifier: ViewModifier {
    let title: String
    let onBack: () -> Void
    let showsSeparator: Bool

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarRole(.editor)
            .tint(Color.subBlack)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackNavigationButton(action: onBack)
                }
            }
            .navigationBarBackground(isVisible: showsSeparator)
            .navigationBarSeparator(isVisible: showsSeparator)
    }
}

/// 뒤로가기 버튼, 중앙 타이틀, 우측 액션을 함께 표시하는 SwiftUI 네이티브 내비게이션 바 modifier.
/// 탭 루트 헤더용 `CustomNavigationBar`와 달리 push 서브 화면 전용이다.
/// `showsSeparator`가 true이면 내비게이션 바 아래 구분선을 표시한다.
private struct BackNavigationBarWithTrailingModifier<Trailing: View>: ViewModifier {
    let title: String
    let onBack: () -> Void
    let showsSeparator: Bool
    let trailing: () -> Trailing

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarRole(.editor)
            .tint(Color.subBlack)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackNavigationButton(action: onBack)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailing()
                }
            }
            .navigationBarBackground(isVisible: showsSeparator)
            .navigationBarSeparator(isVisible: showsSeparator)
    }
}

/// PopPang 공통 뒤로가기 버튼.
private struct BackNavigationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DSKitResource.image("backButton")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.subBlack)
                .frame(width: 32, height: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    /// 구분선이 필요한 내비게이션 바에서만 toolbar 배경을 명시적으로 표시한다.
    @ViewBuilder
    func navigationBarBackground(isVisible: Bool) -> some View {
        if isVisible {
            toolbarBackground(Color.subWhite, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    /// 필요할 때 화면 콘텐츠 상단에 내비게이션 구분선을 그린다.
    @ViewBuilder
    func navigationBarSeparator(isVisible: Bool) -> some View {
        if isVisible {
            overlay(alignment: .top) {
                Divider()
            }
        } else {
            self
        }
    }
}

public extension View {
    /// 뒤로가기 버튼과 중앙 타이틀을 가진 PopPang 공통 내비게이션 바를 적용한다.
    /// 탭 루트 화면이 아니라 뒤로가기가 필요한 push 서브 화면에 사용한다.
    /// - Parameter showsSeparator: 내비게이션 바 아래 구분선 표시 여부.
    func ppBackNavigationBar(
        title: String,
        showsSeparator: Bool = false,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(BackNavigationBarModifier(
            title: title,
            onBack: onBack,
            showsSeparator: showsSeparator
        ))
    }

    /// 뒤로가기 버튼, 중앙 타이틀, 우측 액션을 가진 PopPang 공통 내비게이션 바를 적용한다.
    /// 탭 루트 화면이 아니라 뒤로가기가 필요한 push 서브 화면에 사용한다.
    /// - Parameter showsSeparator: 내비게이션 바 아래 구분선 표시 여부.
    func ppBackNavigationBar<Trailing: View>(
        title: String,
        showsSeparator: Bool = false,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(BackNavigationBarWithTrailingModifier(
            title: title,
            onBack: onBack,
            showsSeparator: showsSeparator,
            trailing: trailing
        ))
    }
}
