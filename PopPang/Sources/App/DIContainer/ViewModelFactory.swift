//
//  ViewModelFactory.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import Foundation

final class ViewModelFactory {
    static let shared = ViewModelFactory()
    private init() {}
    
    func createRoot() -> RootViewModel {
        RootViewModel()
    }
    
    func createHome(userUuid: String) -> HomeViewModel {
        HomeViewModel(userUuid: userUuid)
    }
    
    func createCalendar(userUuid: String) -> CalendarViewModel {
        CalendarViewModel(userUuid: userUuid)
    }
    
    func createMapViewModel(userUuid: String) -> MapViewModel {
        MapViewModel(userUuid: userUuid)
    }
    
    func createBookmark(userUuid: String) -> FavoriteViewModel {
        FavoriteViewModel(userUuid: userUuid)
    }
    
    func createProfile(userUuid: String, isAlerted: Bool) -> ProfileViewModel {
        ProfileViewModel(userUuid: userUuid, isAlerted: isAlerted)
    }
}
