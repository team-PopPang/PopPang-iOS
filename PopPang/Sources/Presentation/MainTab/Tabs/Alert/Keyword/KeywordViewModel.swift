//
//  KeywordViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import Foundation

final class KeywordViewModel: ObservableObject {
    @Dependency private var userUsecase: UserUsecaseProtocol
    @Published var keywordList: [Keyword] = []
    private let maxKeywordCount: Int = 5
    
    let userUuid: String
    init(userUuid: String) {
        self.userUuid = userUuid
        
        Task {
            await fetchKeywordList()
        }
    }
    
    // MARK: - 키워드 조회
    private func fetchKeywordList() async {
        do {
            let keywords = try await userUsecase.getAlertKeywordList(userUuid: userUuid)
            await MainActor.run {
                self.keywordList = keywords
            }
        } catch {
            print("❌ KeywordViewModel Error: \(error)")
        }
    }
}

extension KeywordViewModel {
    
    // MARK: - 키워드 추가
    func addKeyword(_ newKeyword: String) {
        
        // 공백이면 무시한다
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 키워드는 최대 5개까지 가능하다
        if keywordList.count >= maxKeywordCount {
            AlertManager.shared.showKeywordLimitAlert()
            return
        }
                
        // 중복 방지
        let keyword = Keyword(keyword: trimmed)
        guard !keywordList.contains(keyword) else { return }
        keywordList.append(keyword)
        
        Task {
            do {
                try await userUsecase.addAlertKeyword(userUuid: userUuid, alertKeyword: keyword.keyword)
            } catch {
                print("❌ KeywordViewModel.addKeyword Error: \(error)")
            }
        }
    }
    
    // MARK: - 키워드 삭제
    func removeKeyword(at index: Int, keyword: String) {
        keywordList.remove(at: index)
        Task {
            do {
                try await userUsecase.removeAlertKeyword(userUuid: userUuid, alertKeyword: keyword)
            } catch {
                print("❌ KeywordViewModel.removeKeyword Error: \(error)")
            }
        }
    }
}
