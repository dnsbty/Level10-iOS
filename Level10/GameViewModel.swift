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
    @Published var newCard: Card?
    @Published var newCardSelected = false
    @Published var players: [Player] = []
    @Published var selectedIndices = Set<Int>()
    @Published var table: [String: [Int: [Card]]] = [:]
    @Published var tempTable: [Int: [Card]] = [:]
    
    var drawnCard: Card?
    var hasDrawn = false
    var isCreator = false
    var joinCode: String?
    var levels: [String: Level] = [:]
    
    private let joinCodeKey = "joinCode"
    
    var isCurrentPlayer: Bool {
        return UserManager.shared.id == currentPlayer
    }
    
    var inviteUrl: String {
        var configuration = Configuration()
        guard let joinCode = joinCode else { return configuration.environment.apiBaseUrl }
        return "\(configuration.environment.apiBaseUrl)/join/\(joinCode)"
    }
    
    var selectedCards: [Card] {
        var cards = [Card]()
        for index in selectedIndices { cards.append(hand[index]) }
        if let newCard = newCard, newCardSelected { cards.append(newCard) }
        return cards
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCurrentPlayerUpdate), name: .currentPlayerDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCreateGame), name: .didCreateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDrawCard), name: .didDrawCard, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJoinGame), name: .didJoinGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLeaveGame), name: .didLeaveGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCardDrawError), name: .didReceiveCardDrawError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameCreationError), name: .didReceiveGameCreationError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStateUpdate), name: .didReceiveGameState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate), name: .didReceivePresenceUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandCountsUpdated), name: .didReceiveUpdatedHandCounts, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerListUpdate), name: .didReceiveUpdatedPlayerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDiscardTopChange), name: .discardTopDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStart), name: .gameDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandUpdate), name: .handDidUpdate, object: nil)
        
        maybeConnectToExistingGame()
    }
    
    func levelGroups(player: String) -> [LevelGroup] {
        guard let playerLevel = levels[player] else { return [] }
        return playerLevel.groups
    }
    
    func addToTable(_ index: Int) {
        if let _ = tempTable[index] {
            tempTable[index]!.append(contentsOf: selectedCards.sorted())
        } else {
            tempTable[index] = selectedCards.sorted()
        }
        
        for index in selectedIndices.sorted(by: { $0 > $1 }) { hand.remove(at: index) }
        if newCardSelected { newCard = nil }
        selectedIndices.removeAll()
        newCardSelected = false
    }
    
    func clearTempTableGroup(_ index: Int) {
        if let tabledCards = tempTable[index] {
            hand.append(contentsOf: tabledCards)
            hand.sort()
            tempTable.removeValue(forKey: index)
            
            if hasDrawn {
                newCard = drawnCard
                hand.removeAll(where: { $0 == newCard })
            }
        }
        
    }
    
    func toggleIndexSelected(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    private func maybeConnectToExistingGame() {
        if let joinCode = UserDefaults.standard.string(forKey: joinCodeKey) {
            Task {
                do {
                    try await NetworkManager.shared.reconnectToGame(withCode: joinCode)
                } catch {
                    print("Error reconnecting to game")
                }
            }
        }
    }
    
    private func saveJoinCode(_ joinCode: String?) {
        UserDefaults.standard.set(joinCode, forKey: joinCodeKey)
    }
    
    // MARK: Notification Handlers
    
    @objc private func onCardDrawError(_ notification: Notification) {
        // TODO: Show an alert if drawing a card fails
    }
    
    @objc private func onCreateGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        saveJoinCode(joinCode)
        
        DispatchQueue.main.async {
            self.isCreator = true
            self.joinCode = joinCode
            self.currentScreen = .lobby
        }
    }
    
    @objc private func onCurrentPlayerUpdate(_ notification: Notification) {
        guard let player = notification.userInfo?["player"] as? String else { return }
        DispatchQueue.main.async {
            self.currentPlayer = player
            self.hasDrawn = false
        }
    }
    
    @objc private func onDiscardTopChange(_ notification: Notification) {
        let discardTop = notification.userInfo?["discardTop"] as? Card
        DispatchQueue.main.async { self.discardPileTopCard = discardTop }
    }
    
    @objc private func onDrawCard(_ notification: Notification) {
        guard let newCard = notification.userInfo?["newCard"] as? Card else { return }
        DispatchQueue.main.async {
            self.drawnCard = newCard
            self.newCard = newCard
            self.hasDrawn = true
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
    
    @objc private func onGameStateUpdate(_ notification: Notification) {
        guard let currentPlayer = notification.userInfo?["currentPlayer"] as? String,
              var hand = notification.userInfo?["hand"] as? [Card],
              let handCounts = notification.userInfo?["handCounts"] as? [String: Int],
              let hasDrawn = notification.userInfo?["hasDrawn"] as? Bool,
              let levels = notification.userInfo?["levels"] as? [String: Level],
              let players = notification.userInfo?["players"] as? [Player]
        else { return }
        
        let discardTop = notification.userInfo?["discardTop"] as? Card
        
        var newCard: Card?
        if hasDrawn {
            newCard = hand[0]
            hand.remove(at: 0)
        }
        
        DispatchQueue.main.async {
            self.currentPlayer = currentPlayer
            self.currentScreen = .game
            self.discardPileTopCard = discardTop
            self.drawnCard = newCard
            self.hand = hand.sorted()
            self.handCounts = handCounts
            self.hasDrawn = hasDrawn
            self.levels = levels
            self.newCard = newCard
            self.players = players
        }
    }
    
    @objc private func onHandCountsUpdated(_ notification: Notification) {
        guard let handCounts = notification.userInfo?["handCounts"] as? [String: Int] else { return }
        DispatchQueue.main.async { self.handCounts = handCounts }
    }
    
    @objc private func onHandUpdate(_ notification: Notification) {
        guard let hand = notification.userInfo?["hand"] as? [Card] else { return }
        
        DispatchQueue.main.async {
            self.drawnCard = nil
            self.newCard = nil
            self.hand = hand.sorted()
            self.selectedIndices.removeAll()
            self.newCardSelected = false
        }
    }
    
    @objc private func onJoinGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        saveJoinCode(joinCode)
        
        DispatchQueue.main.async {
            self.isCreator = false
            self.joinCode = joinCode
            self.currentScreen = .lobby
        }
    }
    
    @objc private func onLeaveGame(_ notification: Notification) {
        saveJoinCode(nil)
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
