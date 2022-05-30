//
//  GameViewModel.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

class GameViewModel: ObservableObject {
    @Published var connectedPlayers = Set<String>()
    @Published var currentPlayer: String?
    @Published var currentScreen = Screen.home
    @Published var discardPileTopCard: Card?
    @Published var hand: [Card] = []
    @Published var handCounts: [String: Int] = [:]
    @Published var isCreator = false
    @Published var joinCode: String?
    @Published var levels: [String: Level] = [:]
    @Published var players: [Player] = []
    
    var inviteUrl: String {
        var configuration = Configuration()
        guard let joinCode = joinCode else { return configuration.environment.apiBaseUrl }
        return "\(configuration.environment.apiBaseUrl)/join/\(joinCode)"
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCreateGame), name: .didCreateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJoinGame), name: .didJoinGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLeaveGame), name: .didLeaveGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameCreationError), name: .didReceiveGameCreationError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerListUpdate), name: .didReceiveUpdatedPlayerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate), name: .didReceivePresenceUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStart), name: .gameDidStart, object: nil)
    }
    
    func levelGroups(player: String) -> [LevelGroup] {
        guard let playerLevel = levels[player] else { return [] }
        return playerLevel.groups
    }
    
    // MARK: Notification Handlers
    
    @objc private func onCreateGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        
        DispatchQueue.main.async {
            self.isCreator = true
            self.joinCode = joinCode
            self.currentScreen = .lobby
        }
    }
    
    @objc private func onGameCreationError(_ notification: Notification) {
        // TODO: Show an alert if game creation fails
    }
    
    @objc private func onGameStart(_ notification: Notification) {
        guard let currentPlayer = notification.userInfo?["currentPlayer"] as? String,
              let discardTop = notification.userInfo?["discardTop"] as? Card,
              let hand = notification.userInfo?["hand"] as? [Card],
              let levels = notification.userInfo?["levels"] as? [String: Level],
              let players = notification.userInfo?["players"] as? [Player]
        else { return }
        
        let handCounts = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 10) })
        
        DispatchQueue.main.async {
            self.currentPlayer = currentPlayer
            self.discardPileTopCard = discardTop
            self.hand = hand
            self.handCounts = handCounts
            self.levels = levels
            self.players = players
            self.currentScreen = .game
        }
    }
    
    @objc private func onJoinGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        
        DispatchQueue.main.async {
            self.isCreator = false
            self.joinCode = joinCode
            self.currentScreen = .lobby
        }
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
