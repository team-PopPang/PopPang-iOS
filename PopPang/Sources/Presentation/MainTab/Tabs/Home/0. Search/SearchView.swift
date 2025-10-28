//
//  SearchView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI
import Kingfisher
import Combine

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
                    /*
                    IconButton {
                        print("알림 버튼 클릭됨")
                    }
                    .padding(.leading, 15)
                     */
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
                            Text(rootViewModel.user?.nickname ?? "홍길동")
                                .foregroundStyle(Color.mainOrange)
                                .font(.scdream(.bold, size: 12))
                            Text("님의 최근 본 검색어예요")
                                .font(.scdream(.regular, size: 12))
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
                PopupDetailView(popup: popup)
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

private struct SearchGridPopupCell: View {
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    let popup: Popup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 217, alignment: .center)
                
                GeometryReader { geo in
                    KFImage(URL(string: popup.imageUrlList[0]))
                        .placeholder {
                            Rectangle()
                                .frame(height: 217)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 217, alignment: .center)
                        .clipped() // 넘치는 영역 완전히 제거
                }
            }
            .frame(height: 217)
            
            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)
            
            Text(popup.name)
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1) // 한줄만 표시
                .truncationMode(.tail) // 넘치면 ...으로 표시
                .padding(.top, 5)
            
            HStack {
                Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                Text("-")
                Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
            }
            .font(.scdream(.regular, size: 12))
            .foregroundStyle(Color.mainGray)
            .padding(.top, 5)
            .padding(.leading, -1)
        }
    }
}



#Preview {
    SearchView(userUuid: "1234")
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(SearchViewModel(userUuid: "1234"))
        .environmentObject(RootViewModel())
}

final class SearchViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var searchPopupList: [Popup] = []
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init(userUuid: String) {
        self.userUuid = userUuid
        
        // 검색 디바운스 적용
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                
                if text.isEmpty {
                    // 검색어를 모두 지우면 그리드 배열도 초기화
                    self.searchPopupList = []
                } else {
                    // 디바운스 타이밍에 최근 검색어 저장
                    UserDefaultsManager.add(text)
                    Task {
                        await self.getSearchPopupList(searchText: text)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

extension SearchViewModel {
    func getSearchPopupList(searchText: String) async {
        do {
            let searchPopupList = try await popupUsecase.searchPopupList(searchText: searchText)
            await MainActor.run {
                self.searchPopupList = searchPopupList
            }
        } catch {
            print("❌ SearchViewModel.getSearchPopupList(): \(error)")
        }
    }
}
