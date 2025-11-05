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
    
    let userUuid: String
    init(userUuid: String) {
        self.userUuid = userUuid
        Task {
            await fetchKeywordList()
        }
    }
    
    // MARK: - 키워드 조회
    func fetchKeywordList() async {
        do {
            let keywords = try await userUsecase.getAlertKeywordList(userUuid: userUuid)
            await MainActor.run {
                self.keywordList = keywords
            }
        } catch {
            print("❌ KeywordViewModel Error: \(error)")
        }
    }
    
    // MARK: - 키워드 추가(로컬, 서버API 연ㅁ동전)
    func addKeyword(_ newKeyword: String) {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let keyword = Keyword(keyword: trimmed)
                
        // 중복 방지
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
    
    // MARK: - 키워드 삭제(로컬, 서버API 연동전)
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
