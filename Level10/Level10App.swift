//
//  Level10App.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

enum CurrentScreen {
    case home, create, join, lobby, game
}

final class Navigation: ObservableObject {
    @Published var currentScreen = CurrentScreen.home
}

@main
struct Level10App: App {
    @StateObject var navigation = Navigation()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch navigation.currentScreen {
                case .home:
                    HomeView()
                case .create:
                    CreateGameView()
                case .join:
                    JoinGameView()
                case .lobby:
                    LobbyView()
                case .game:
                    GameView()
                }
            }
            .environmentObject(navigation)
        }
    }
}
