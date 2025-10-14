//
//  KeywordView.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import SwiftUI

final class KeywordViewModel: ObservableObject {
    @Dependency private var userUsecase: UserUsecaseProtocol
    @Published var keywordList: [Keyword] = []
    
    let uuid: String
    init(uuid: String) {
        self.uuid = uuid
        Task {
            await fetchKeywordList()
        }
    }
    
    // MARK: - 키워드 조회
    func fetchKeywordList() async {
        do {
            let keywords = try await userUsecase.getAlertKeywordList(uuid: uuid)
            await MainActor.run {
                self.keywordList = keywords
                print("키워드리스트: \(keywords)")
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
    }
    
    // MARK: - 키워드 삭제(로컬, 서버API 연동전)
    func removeKeyword(at index: Int) {
        keywordList.remove(at: index)
    }
}


struct KeywordView: View {
    @ObservedObject var keywordViewModel: KeywordViewModel
    @State private var text: String = ""
    @State private var categories = [
        "애니메이션", "캐릭터", "화장품", "패션",
        "식음료"
    ]
    
    var body: some View {
        VStack {
            
            HStack(spacing: .contentPadding) {
                RoundedTextField(placeholder: "알림 받고 싶은 키워드를 입력해주세요",
                                 text: $text)
                Button {
                    keywordViewModel.addKeyword(text)
                    text = ""
                } label: {
                    Image("plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            }
            
            ForEach(Array(keywordViewModel.keywordList.enumerated()), id: \.1.id ) { index, keyword in
                HStack {
                    Text(keyword.keyword)
                        .ppStyleFont(.scdream(.medium, size: 12))
                    Spacer()
                    Button {
                        keywordViewModel.removeKeyword(at: index)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mainGray)
                    }
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("홍길동")
                        .foregroundStyle(Color.mainOrange)
                        .font(.scdream(.bold, size: 12))
                    Text("님의 최근 본 검색어예요")
                        .font(.scdream(.regular, size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // 선택 버튼들
                SearchFlowLayout(data: categories, id: \.self) { category in
                    SearchFlowButton(title: category) {
                        self.text = category
                    } onRemove: {
                        if let index = categories.firstIndex(of: category) {
                            categories.remove(at: index)
                        }
                    }
                }
                .padding(.top, 15)
            }
            .padding(.top, 30)
            
            
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, .contentPadding)
    }
}

#Preview {
    KeywordView(keywordViewModel: KeywordViewModel(uuid: "1234"))
}

