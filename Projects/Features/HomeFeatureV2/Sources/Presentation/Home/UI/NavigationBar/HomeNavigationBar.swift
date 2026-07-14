//
//  HomeNavigationBar.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 7/14/26.
//

import SwiftUI
import DSKit

struct HomeNavigationBar: View {
    let userUuid: String
    let showsPopupRequestManagement: Bool
    
    let onSearch: (String) -> Void
    let onAlert: (String) -> Void
    let onReport: () -> Void
    let onManagePopupRequests: () -> Void
    
    var body: some View {
        CustomNavigationBar {
            Text("POP PANG")
                .ppStyleFont(.scdream(.black, size: 20))
                .foregroundStyle(Color.mainOrange)
            
            Spacer()

            IconButton(image: "SearchDark", imageSize: 25) {
                onSearch(userUuid)
            }
            .accessibilityIdentifier("home_search_button")

            IconButton {
                onAlert(userUuid)
            }

            HomeReportButton {
                onReport()
            }
            .accessibilityIdentifier("home_popup_report_button")

            if showsPopupRequestManagement {
                HomePopupRequestManagementButton {
                    onManagePopupRequests()
                }
                .accessibilityIdentifier("home_popup_request_management_button")
            }
        }
    }
}

private struct HomeReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .offset(y: -1.5)
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HomePopupRequestManagementButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "tray.full")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
