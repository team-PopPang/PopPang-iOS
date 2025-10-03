//
//  GoogleAuthRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation
import GoogleSignIn

final class GoogleAuthRepositoryImpl: GoogleAuthRepositoryProtocol {
    
    @MainActor
    func googleLogin() async throws -> User {
        //현재 앱에서 최상위 뷰 컨트롤러를 찾는 부분
          let presentingVC = try await MainActor.run {
              guard let vc = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                  .windows.first?.rootViewController else {
                  throw GoogleAuthError.noRootViewController
              }
              return vc
          }
        
        // Google 로그인 화면 실행
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
        let user = result.user
        
        // 토큰 및 정보 추출
        let responseDTO = GoogleResponseDTO(oauthId: user.userID ?? "",
                                            idToken: user.idToken?.tokenString ?? "")
        print("✅ Google idToken: \(responseDTO.idToken)")
        
        let userDTO = try await NetworkProvider.shared.googleProvider.asyncRequest(.login(idToken: responseDTO.idToken),
                                                                                   decodeTo: UserDTO.self)
        return userDTO.toModel()
    }
    
    func googleRegister(user: User) async throws -> User {
        let userDTO = try await NetworkProvider.shared.googleProvider.asyncRequest(.signup(userDTO: user.toDTO()), decodeTo: UserDTO.self)
        return userDTO.toModel()
    }
}



//
//
//extension RootViewModel {
//
//    func signIn() {
//        //현재 앱에서 최상위 뷰 컨트롤러를 찾는 부분
//        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
//            return
//        }
//
//        GIDSignIn.sharedInstance.signIn(//구글 로그인 프로세스를 시작
//            withPresenting: presentingViewController)
//        { _, error in
//            if let error = error {
//                print("error: \(error.localizedDescription)")
//            }
//
//            self.checkUserInfo()//현재 사용자의 정보를 확인하는 로직 실행
//        }
//    }
//
//    func checkUserInfo() {
//        print("토큰받기")
//        if GIDSignIn.sharedInstance.currentUser != nil {//현재 사용자가 로그인되어 있는지 확인
//            let user = GIDSignIn.sharedInstance.currentUser
//            guard let user = user else {
//                return
//            }
//            googleResponseDTO.oauthId = user.userID ?? "" //사용자의 고유 ID
//            googleResponseDTO.idToken = user.idToken?.tokenString ?? ""//사용자의 ID 토큰
//            print("구글 토큰 받기: \(googleResponseDTO)")
//        } else {
//            print("error: Not Logged In")
//        }
//    }
//}
