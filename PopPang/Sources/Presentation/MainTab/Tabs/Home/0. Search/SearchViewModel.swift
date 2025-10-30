//
//  SearchViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import SwiftUI
import Combine

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
            .debounce(for: .milliseconds(500),
                      scheduler: RunLoop.main)
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
