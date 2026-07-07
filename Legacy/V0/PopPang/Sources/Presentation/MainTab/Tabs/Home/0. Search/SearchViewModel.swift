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
        bindDebounce()
    }
    
    // searchText 변화를 동작과 연결(바인딩)한다
    private func bindDebounce() {
        
        // MARK: - API 호출은 0.3초 디바운스
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                
                if text.isEmpty {
                    self.searchPopupList = []
                } else {
                    self.getSearchPopupList(searchText: text)
                }
            }
            .store(in: &cancellables)
        
        // MARK: - 최근 검색어 저장은 1초 디바운스
        $searchText
            .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { text in
                guard !text.isEmpty else { return }
                UserDefaultsManager.add(text)
            }
            .store(in: &cancellables)
    }
}

extension SearchViewModel {
    
    // MARK: - 검색 팝업 리스트 가져오기
    func getSearchPopupList(searchText: String) {
        Task {
            do {
                let searchPopupList = try await popupUsecase.getPersonalSearchPopupList(userUuid: userUuid, searchText: searchText)
                await MainActor.run {
                    self.searchPopupList = searchPopupList
                }
            } catch {
                Logger.e("\(error)")
            }
        }
    }
}
