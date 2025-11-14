//
//  SearchView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchViewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    @State private var selectedPopup: Popup? = nil
    let userUuid: String

    @State private var categories: [String] = UserDefaultsManager.load()
    
    init(userUuid: String) {
        self.userUuid = userUuid
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(userUuid: userUuid))
    }
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search & Alert
                HStack(spacing: 0) {
                    Button {
                        dismiss()
                    } label: {
                        Image("backButton")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                            .foregroundStyle(Color.subBlack)
                    }
                    .padding(.trailing, 10)
                    
                    SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                    text: $searchViewModel.searchText)
                    .focused($isFocused)
                }
                .padding(.top, 10)
                .padding(.leading, .contentPadding)
                .padding(.trailing, 15)
                .padding(.bottom, 10)
                
                VStack(spacing: 0) {
                    // MARK: - 최근 본 검색어
                    if searchViewModel.searchPopupList.isEmpty {
                        // MARK: - 글자
                        HStack(spacing: 0) {
                            if !categories.isEmpty {
                                Text(rootViewModel.user?.nickname ?? "홍길동")
                                    .foregroundStyle(Color.mainOrange)
                                    .font(.scdream(.bold, size: 12))
                                Text("님의 최근 본 검색어예요")
                                    .font(.scdream(.regular, size: 12))
                            } else {
                                Text(rootViewModel.user?.nickname ?? "홍길동")
                                    .foregroundStyle(Color.mainOrange)
                                    .font(.scdream(.bold, size: 12))
                                Text("님의 최근 본 검색어가 없습니다")
                                    .font(.scdream(.regular, size: 12))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // MARK: - 선택 버튼들
                        SearchFlowLayout {
                            ForEach(categories, id: \.self) { category in
                                SearchFlowButton(title: category) {
                                    self.searchViewModel.searchText = category
                                } onRemove: {
                                    if let index = categories.firstIndex(of: category) {
                                        categories.remove(at: index)
                                        UserDefaultsManager.remove(category)
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .padding(.top, 15) // 상단 여백만
                    }

                    // MARK: - GridView
                    SearchGridPopupScrollView(viewModel: searchViewModel) { popup in
                        selectedPopup = popup
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, .contentPadding)
                
                Spacer()
            }
            .navigationDestination(item: $selectedPopup) { popup in
                PopupDetailView(userUuid: userUuid, popup: popup)
            }
        }
        .task {
            isFocused = true
        }
    }
}

private struct SearchGridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: SearchViewModel
    var onSelect: (Popup) -> Void
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.searchPopupList) { popup in
                    
                    VStack(alignment: .leading) {
                        SearchGridPopupCell(popup: popup)
                            .onTapGesture {
                                onSelect(popup)
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView(userUuid: "1234")
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(SearchViewModel(userUuid: "1234"))
        .environmentObject(RootViewModel())
}

