import DSKit
import SwiftUI

/// 회원가입 V2 피그마 값. DSKit 토큰 목록에 없는 값이라 가입 화면에서만 쓴다.
enum RegisterLayout {
    static let screenHorizontal: CGFloat = 20
    static let buttonHorizontal: CGFloat = 23
    static let headerHeight: CGFloat = 37
    static let progressSize = CGSize(width: 270, height: 4)
    static let titleTop: CGFloat = 20
    static let titleLineHeight: CGFloat = 35.28
    static let fieldHeight: CGFloat = 48
    static let fieldRadius: CGFloat = 12
    static let fieldPadding: CGFloat = 16
    static let checkButtonSize = CGSize(width: 62, height: 45)
    static let checkButtonRadius: CGFloat = 5
    static let messageTop: CGFloat = 13
    static let nextButtonHeight: CGFloat = 52
    static let nextButtonRadius: CGFloat = 10
    static let sectionLabelTop: CGFloat = 34
    static let chipsTop: CGFloat = 7
    static let chipHeight: CGFloat = 39
    static let chipHorizontal: CGFloat = 15
    static let chipSpacing: CGFloat = 8
    static let summaryBottom: CGFloat = 20
    static let subtitleTop: CGFloat = 6
    static let keywordFieldTop: CGFloat = 23
    static let keywordFieldHeight: CGFloat = 50
    static let addButtonWidth: CGFloat = 64
    static let myKeywordLabelTop: CGFloat = 38
    static let myKeywordChipsTop: CGFloat = 11
    static let popularLabelTop: CGFloat = 28
    static let popularChipsTop: CGFloat = 12
    /// 홈 바가 없는 기기(SE)에서 아래 버튼 밑 여백
    static let noHomeBarBottom: CGFloat = 16
}

/// 가입 화면 섹션 라벨. 피그마는 ExtraBold 14 `#333333`이다.
struct RegisterSectionLabel: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text, bundle: .module)
            .ppStyleFont(.scdream(.extraBold, size: 14), lineHeightPt: 17)
            .foregroundStyle(Color.mainBlack)
    }
}

/// 가입 화면 칩. 글자는 부르는 쪽에서 만든다("✓ 디저트", "두쫀쿠  ×", "+ 소금빵").
struct RegisterChip: View {
    enum Style {
        /// 흰 바탕, 회색 테두리, Light 14 (카테고리 기본, 인기 키워드)
        case normal
        /// 연주황 바탕, 주황 테두리, ExtraBold 14 주황 (고른 카테고리)
        case selected
        /// 연주황 바탕, 테두리 없음, ExtraBold 14 주황 (내 키워드)
        case added
    }

    let text: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: text)
                .font(Font(UIFont.scdream(style == .normal ? .light : .extraBold, size: 14)))
                .foregroundStyle(style == .normal ? Color.mainBlack : Color.mainOrange)
                .padding(.horizontal, RegisterLayout.chipHorizontal)
                .frame(height: RegisterLayout.chipHeight)
                .background(
                    Capsule().fill(style == .normal ? Color.subWhite : Color.registerChipSelected)
                )
                .overlay(
                    Capsule().stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(style == .selected ? .isSelected : [])
    }

    private var borderColor: Color {
        switch style {
        case .normal: .registerChipBorder
        case .selected: .mainOrange
        case .added: .registerChipSelected
        }
    }
}

/// 칩을 가로로 늘어놓고 폭이 모자라면 다음 줄로 넘긴다. 가로·세로 간격이 같다.
struct RegisterChipFlowLayout: Layout {
    var spacing: CGFloat = RegisterLayout.chipSpacing

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if !current.indices.isEmpty, nextWidth > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// 가입 단계 위의 뒤로가기, 진행 막대, 단계 숫자
struct RegisterHeader: View {
    let step: Int
    let totalSteps: Int
    let showsBack: Bool
    let onBack: () -> Void

    var body: some View {
        ZStack {
            progressBar

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.registerText)
                        .frame(width: 29, height: RegisterLayout.headerHeight, alignment: .leading)
                }
                .opacity(showsBack ? 1 : 0)
                .disabled(!showsBack)
                .accessibilityLabel(Text("뒤로", bundle: .module, comment: "Back button in sign-up steps"))

                Spacer()

                Text(verbatim: "\(step)/\(totalSteps)")
                    .ppStyleFont(.scdream(.medium, size: 14), lineHeightPt: 22)
                    .foregroundStyle(Color.onboardingGray)
            }
            .padding(.horizontal, RegisterLayout.screenHorizontal)
        }
        .frame(height: RegisterLayout.headerHeight)
    }

    private var progressBar: some View {
        let size = RegisterLayout.progressSize
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.registerTrack)
            Capsule()
                .fill(Color.mainOrange)
                .frame(width: size.width * CGFloat(step) / CGFloat(totalSteps))
        }
        .frame(width: size.width, height: size.height)
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}

/// 가입 단계 제목. 피그마는 ExtraBold 24, 줄 높이 35.28이다.
struct RegisterTitle: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text, bundle: .module)
            .ppStyleFont(.scdream(.extraBold, size: 24), lineHeightPt: RegisterLayout.titleLineHeight)
            .foregroundStyle(Color.subBlack)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 가입 화면 아래 주황 버튼. `MainOrangeButton`과 모서리·높이·글꼴이 달라 가입 화면에서만 쓴다.
struct RegisterNextButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font(UIFont.scdream(.medium, size: 15)))
                .foregroundStyle(Color.subWhite)
                .frame(maxWidth: .infinity)
                .frame(height: RegisterLayout.nextButtonHeight)
                .background(isEnabled ? Color.mainOrange : Color.mainGray2)
                .clipShape(RoundedRectangle(cornerRadius: RegisterLayout.nextButtonRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
    }
}
