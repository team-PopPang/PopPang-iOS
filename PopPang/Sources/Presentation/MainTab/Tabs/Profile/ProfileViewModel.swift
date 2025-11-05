//
//  ProfileViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/26/25.
//

import SwiftUI

final class ProfileViewModel: ObservableObject {
    @Dependency private var userUsecase: UserUsecaseProtocol
    var userUuid: String
    
    init(userUuid: String) {
        self.userUuid = userUuid
    }
    
    enum Action {
        case checkNewNickname                    // 새 닉네임 중복 확인
        case updateNewNickname(String, String)   // 새 닉네임으로 갱신
        case hardDeleteUser
    }
    
    func send(action: Action, completion: (() -> Void)? = nil) {
        switch action {
        case .checkNewNickname:
            // 닉네임이 빈값이면 서버 안탐
            guard !newNickname.isEmpty else { return }
            
            switch validationState {
            case .invalidSpace, .tooShort: return // 로컬에서 이미 실패 상태면 서버 안탐
            default: break                        // 그 외에는 허용
            }
            
            // 확인중
            validationState = .checking
            
            // 닉네임 중복 확인
            checkNickname()

        case .updateNewNickname(let userUuid, let newNickname):
            updateNickname(userUuid: userUuid, newNickname: newNickname, completion: completion)
            
        case .hardDeleteUser:
            hardDeleteUser()
        }
    }
    
    @Published var validationState: NicknameValidationState = .none
    @Published var newNickname: String = "" {
        didSet {
            self.checkLocalNickname()
        }
    }
    
    // 로컬 검증 로직
    private func checkLocalNickname() {
        
        // 미검증
        guard !newNickname.isEmpty else {
            validationState = .none
            return
        }
        
        // 공백여부
        if newNickname.contains(" ") {
            validationState = .invalidSpace
            return
        }
        
        if newNickname.count <= 2 {
            validationState = .tooShort
            return
        }
        
        // 아직 서버 검증 전 단계
        validationState = .none
    }
}

// MARK: - 비동기 함수 동기 함수로 래핑
extension ProfileViewModel {
    // 닉네임 확인
    private func checkNickname() {
        Task {
            do {
                let isDuplicated = try await userUsecase.checkNickname(nickname: newNickname)
                await MainActor.run {
                    self.validationState = isDuplicated ? .duplicate : .success
                }
            } catch {
                print("❌ 중복 확인 실패: \(error)")
            }
        }
    }
    
    // 닉네임 업데이트
    private func updateNickname(userUuid: String,
                                newNickname: String,
                                completion: (() -> Void)? = nil) {
        Task {
            do {
                try await userUsecase.updateNickname(userUuid: userUuid, newNickname: newNickname)
                await MainActor.run {
                    completion?()
                }
            } catch {
                print("❌ ProfileViewModel.updateNickname() Error: \(error)")
            }
        }
    }
    
    // 유저 삭제
    private func hardDeleteUser() {
        Task {
            do {
                try await userUsecase.hardDeleteUser(userUuid: userUuid)
            } catch {
                print("❌ ProfileViewModel.deleteUser() Error: \(error)")
            }
        }
    }
}
