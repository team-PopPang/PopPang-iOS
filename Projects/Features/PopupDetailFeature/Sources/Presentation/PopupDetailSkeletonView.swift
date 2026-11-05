import DSKit
import SwiftUI

/// 상세 데이터를 받는 동안 보여 주는 자리 (스펙 D-11).
///
/// 불러온 뒤의 배치(사진 450 → 제목·태그 → 운영 정보 3줄 → 설명 → 아래 바)를 그대로 따라 그려서
/// 내용이 들어올 때 화면이 덜 흔들리게 한다. 실패해서 다시 요청하는 동안에도 이 화면이 이어진다.
struct PopupDetailSkeletonView: View {
    /// 운영 장소·날짜·시간 줄의 값 폭. 실제 글자처럼 길이를 다르게 둔다.
    private let infoValueWidths: [CGFloat] = [220, 140, 110]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // 사진 자리. 실제 화면처럼 상단 바 아래까지 깐다.
                Rectangle()
                    .fill(PPColor.divider)
                    .frame(height: 450)

                VStack(alignment: .leading, spacing: PPSpacing.s12) {
                    PPSkeletonBlock(width: 220, height: 22)
                    PPSkeletonBlock(width: 48, height: 22, radius: 11)

                    divider

                    ForEach(infoValueWidths.indices, id: \.self) { index in
                        HStack(spacing: PPSpacing.s20) {
                            PPSkeletonBlock(width: 62, height: 17)
                            PPSkeletonBlock(width: infoValueWidths[index], height: 17)
                        }
                    }

                    divider

                    ForEach(0..<3, id: \.self) { _ in
                        PPSkeletonBlock(height: 15)
                    }
                    PPSkeletonBlock(height: 15)
                        .padding(.trailing, 80)
                }
                .padding(.top, PPSpacing.s20)
                .padding(.horizontal, PPSpacing.screenHorizontal)
            }
            // 화면보다 길면(iPhone SE 등) 실제 화면처럼 위에서부터 보이고 아래는 잘린다.
            // minHeight 0이 있어야 내용 높이(약 760pt)보다 작게 줄어든다.
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .clipped()

            // 아래 바 자리: 공유 버튼과 하트
            HStack(spacing: PPSpacing.s20) {
                PPSkeletonBlock(height: 40, radius: PPRadius.medium)
                Circle()
                    .fill(PPColor.divider)
                    .frame(width: 25, height: 25)
            }
            .padding(.vertical, PPSpacing.s10)
            .padding(.horizontal, PPSpacing.screenHorizontal)
            .padding(.trailing, PPSpacing.s10)
            .background(PPColor.backgroundSecondary)
        }
        .ppSkeletonShimmer()
        .ignoresSafeArea(edges: .top)
        .background(PPColor.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("팝업 정보를 불러오는 중", bundle: .module, comment: "VoiceOver label while the popup detail is loading"))
    }

    private var divider: some View {
        Rectangle()
            .fill(PPColor.divider)
            .frame(height: 1)
            .padding(.vertical, PPSpacing.s4)
    }
}

#Preview {
    PopupDetailSkeletonView()
}
