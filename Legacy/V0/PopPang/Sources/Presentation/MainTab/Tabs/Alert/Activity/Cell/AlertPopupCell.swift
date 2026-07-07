//
//  AlertPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher
import AutoEquatable

//enum RenderCounter {
//    static var cellBodyCount = 0
//}
//
//private func countBody() {
//    RenderCounter.cellBodyCount += 1
//    
//    print(RenderCounter.cellBodyCount)
//}

@AutoEquatable
struct AlertPopupCell: View {
    
    @AutoRequiredChild(\Popup.popupUuid)
    let popup: Popup
    let isLiked: Bool
    let onToggleLike: () -> Void
    
    var body: some View {
        // let _ = countBody()
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                    // MARK: - 이미지
                    KFImage(URL(string: popup.imageUrlList[0]))
                        .downSampled(.medium)
                        .aspectRatio(contentMode: .fill) // 프레임을 채움
                        .frame(width: 106, height: 133)  // 포스트 사이즈
                        .clipped()                       // 넘치는 영역 제거
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                        .padding(.top, 10)
                    
                    Text(popup.name)
                        .font(.scdream(.medium, size: 14))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1) // 한줄만 표시
                        .truncationMode(.tail) // 넘치면 ...으로 표시
                        .padding(.top, 5)
                    
                    Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                        .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                        .foregroundStyle(Color.mainGray)
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    // 조회수
                    HStack(spacing: 5) {
                        
                        Spacer()
                        
                        Image("viewCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                        
                        Text("\(popup.viewCount )")
                            .ppStyleFont(.scdream(.regular, size: 9))
                        
                        
                        
                        Button {
                            onToggleLike()
                            /*
                            Task {
                                await activityViewModel.toggleLike(popup: popup)
                            }
                             */
                        } label: {
                            HStack(spacing: 5) {
                                Image("favoriteCount")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                
                                Text("\(popup.favoriteCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
                            }
                        }
                        .foregroundStyle(isLiked ? Color.mainOrange : Color.mainGray)
                        // .foregroundStyle(activityViewModel.isLiked(popup: popup) ? Color.mainOrange : Color.mainGray)
                        
                    }
                }
                .padding(.leading, 18)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .padding(.vertical, 15)
        // .debugBodyRandomBackground()
    }
}



/*
 AlertPopupCell(...)
     .equatable()

내부 의사 코드
 if oldView == newView {
     // "같으면"
     // body를 다시 계산하지 않음 (리렌더 스킵)
 } else {
     // "다르면"
     // body를 다시 계산함 (리렌더)
 }
 */

/*
 SwiftUI가 body를 다시 계산할 조건”을 ‘같다/다르다’로 표현해서 커스텀하는 것
 - ==가 true를 많이 반환할수록 → 업데이트를 많이 “스킵” (더 공격적인 최적화)
 - ==가 true를 많이 반환할수록 → 업데이트를 많이 “스킵” (더 공격적인 최적화)
 */
//extension AlertPopupCell: Equatable {
//    // 좋아요가 상태 or 좋아요 수가 바뀌면 다른 View로 간주한다
//    static func == (lhs: AlertPopupCell, rhs: AlertPopupCell) -> Bool {
//        print("실행되는데")
//        return lhs.popup.popupUuid == rhs.popup.popupUuid
//        && lhs.isLiked == rhs.isLiked
//        && lhs.popup.favoriteCount == rhs.popup.favoriteCount
//    }
//}






