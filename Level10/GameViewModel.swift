//
//  GameViewModel.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

class GameViewModel: ObservableObject {
    @Published var connectedPlayers = Set<String>()
    @Published var currentScreen = Screen.home
    @Published var joinCode: String?
    @Published var players: [Player] = []
    
    var inviteUrl: String {
        var configuration = Configuration()
        guard let joinCode = joinCode else { return configuration.environment.apiBaseUrl }
        return "\(configuration.environment.apiBaseUrl)/join/\(joinCode)"
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCreateGame), name: .didCreateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLeaveGame), name: .didLeaveGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameCreationError), name: .didReceiveGameCreationError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerListUpdate), name: .didReceiveUpdatedPlayerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate), name: .didReceivePresenceUpdate, object: nil)
    }
    
    @objc private func onCreateGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        
        DispatchQueue.main.async {
            self.joinCode = joinCode
            self.currentScreen = .lobby
        }
    }
    
    @objc private func onGameCreationError(_ notification: Notification) {
        // TODO: Show an alert if game creation fails
    }
    
    @objc private func onLeaveGame(_ notification: Notification) {
        players = []
        joinCode = nil
        connectedPlayers = Set<String>()
        currentScreen = Screen.home
    }
    
    @objc private func onPlayerListUpdate(_ notification: Notification) {
        guard let players = notification.userInfo?["players"] as? [Player] else { return }
        DispatchQueue.main.async { self.players = players }
    }
    
    @objc private func onPresenceUpdate(_ notification: Notification) {
        guard let connectedPlayers = notification.userInfo?["connectedUsers"] as? Set<String> else { return }
        DispatchQueue.main.async { self.connectedPlayers = connectedPlayers }
    }
}
