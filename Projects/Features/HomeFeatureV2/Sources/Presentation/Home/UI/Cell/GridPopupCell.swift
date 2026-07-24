//
//  ListKitGridPopupCell.swift
//  HomeFeature
//
//  Created by 김동현 on 6/15/26.
//

import SwiftUI
import Domain
import Kingfisher
import DSKit

//struct GridPopupCell: View {
//    static let estimatedHeight: CGFloat = 302
//    let popup: Popup
//    let toggleLike: () -> Void
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            ZStack(alignment: .topTrailing) {
//                KFImage(URL(string: popup.imageUrlList.first ?? ""))
//                    .placeholder {
//                        Rectangle()
//                            .fill(Color.subWhite)
//                    }
//                    .downSampled(.gridPopupCell)
//                    .scaledToFill()
//                    .frame(height: 217)
//                    .clipped()
//
//                Button {
//                    toggleLike()
//                } label: {
//                    DSKitResource.image(popup.isFavorited ? "favorite_fill" : "favorite")
//                        .renderingMode(.template)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 25, height: 25)
//                        .foregroundStyle(popup.isFavorited ? Color.mainOrange : Color.subWhite)
//                }
//                .padding(10)
//                .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
//            }
//            .frame(height: 217)
//
//            Text(popup.roadAddress.shortAddress)
//                .font(.scdream(.regular, size: 12))
//                .foregroundStyle(Color.mainBlack)
//                .padding(.top, 10)
//
//            Text(popup.name)
//                .font(.scdream(.medium, size: 14))
//                .foregroundStyle(Color.mainBlack)
//                .lineLimit(1)
//                .truncationMode(.tail)
//                .padding(.top, 5)
//
//            Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
//                .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
//                .foregroundStyle(Color.mainGray)
//                .padding(.top, 5)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .contentShape(Rectangle())
//    }
//}
//


struct GridPopupCell: View {
    static let estimatedHeight: CGFloat = 302

    private static var cellWidth: CGFloat {
        (UIScreen.main.bounds.width - CGFloat.contentPadding * 2 - 15) / 2
    }

    let popup: Popup
    let toggleLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.subWhite)
                            .frame(width: Self.cellWidth, height: 217)
                    }
                    .resizable()
                    .downSampled(.gridPopupCell)
                    .scaledToFill()
                    .frame(width: Self.cellWidth, height: 217)
                    .clipped()

                Button {
                    toggleLike()
                } label: {
                    DSKitResource.image(popup.isFavorited ? "favorite_fill" : "favorite")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundStyle(popup.isFavorited ? Color.mainOrange : Color.subWhite)
                }
                .padding(10)
                .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
            }
            .frame(width: Self.cellWidth, height: 217)

            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)

            Text(popup.name)
                .font(.scdream(.medium, size: 14))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 5)

            Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                .foregroundStyle(Color.mainGray)
                .padding(.top, 5)
        }
        .frame(width: Self.cellWidth, alignment: .leading)
        .contentShape(Rectangle())
    }
}
