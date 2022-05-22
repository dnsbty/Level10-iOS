//
//  Level10App.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI
import SwiftPhoenixClient

enum Screen {
    case home, create, join, lobby, game
}

private struct CurrentScreenKey: EnvironmentKey {
    static var defaultValue: Binding<Screen> = .constant(.home)
}

extension EnvironmentValues {
    var currentScreen: Binding<Screen> {
        get { self[CurrentScreenKey.self] }
        set { self[CurrentScreenKey.self] = newValue }
    }
}

@main
struct Level10App: App {
    @StateObject private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                switch viewModel.currentScreen {
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
            .environment(\.currentScreen, $viewModel.currentScreen)
            .environmentObject(viewModel)
        }
    }
}
