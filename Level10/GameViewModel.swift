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
    @Published var playersReady = Set<String>()
    @Published var roundWinner: Player?
    @Published var selectedIndices = Set<Int>()
    @Published var table: [String: [[Card]]] = [:]
    @Published var tempTable: [Int: [Card]] = [:]
    
    var completedLevel = false
    var drawnCard: Card?
    var gameOver = false
    var hasDrawn = false
    var isCreator = false
    var isReadyForNextRound = false
    var joinCode: String?
    var levels: [String: Level] = [:]
    var roundNumber = 1
    var scores: [Score] = []
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(onAddToTable), name: .didAddToTable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCreateGame), name: .didCreateGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDrawCard), name: .didDrawCard, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEndGame), name: .didEndGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJoinGame), name: .didJoinGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLeaveGame), name: .didLeaveGame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAddToTableError), name: .didReceiveAddToTableError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCardDrawError), name: .didReceiveCardDrawError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameCreationError), name: .didReceiveGameCreationError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStateUpdate), name: .didReceiveGameState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayersReadyUpdate), name: .didReceivePlayersReadyUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate), name: .didReceivePresenceUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandCountsUpdated), name: .didReceiveUpdatedHandCounts, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerListUpdate), name: .didReceiveUpdatedPlayerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSetTable), name: .didSetTable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDiscardTopChange), name: .discardTopDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameOver), name: .gameDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStart), name: .gameDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJoinError), name: .gameJoinError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandUpdate), name: .handDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRoundFinished), name: .roundDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRoundStart), name: .roundDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTableUpdate), name: .tableDidUpdate, object: nil)
        
        maybeConnectToExistingGame()
    }
    
    func addToPlayerTable(playerId: String, index: Int) {
        guard completedLevel, let playerTable = table[playerId], playerTable.count > index else { return }
        HapticManager.playMediumImpact()
        
        Task {
            try? await NetworkManager.shared.addToTable(cards: self.selectedCards, tablePlayerId: playerId, groupPosition: index)
        }
    }
    
    func addToTable(_ index: Int) {
        let level = levels[UserManager.shared.id!]!
        let levelGroup = level.groups[index]
        guard levelGroup.isValid(selectedCards) else { return }
        
        if let _ = tempTable[index] {
            tempTable[index]!.append(contentsOf: selectedCards.sorted())
        } else {
            tempTable[index] = selectedCards.sorted()
        }
        
        for index in selectedIndices.sorted(by: { $0 > $1 }) { hand.remove(at: index) }
        if newCardSelected { newCard = nil }
        selectedIndices.removeAll()
        newCardSelected = false
        
        for groupIndex in level.groups.indices {
            if tempTable[groupIndex] == nil {
                HapticManager.playMediumImpact()
                return
            }
        }
        
        Task {
            let groups = tempTable.keys.sorted().map { tempTable[$0]! }
            try? await NetworkManager.shared.tableCards(table: groups)
        }
    }
    
    func clearTempTableGroup(_ index: Int) {
        HapticManager.playMediumImpact()
        
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
    
    func isConnected(playerId: String) -> Bool {
        return connectedPlayers.contains(playerId)
    }
    
    func isReady(playerId: String) -> Bool {
        return playersReady.contains(playerId)
    }
    
    func levelGroups(player: String) -> [LevelGroup] {
        guard let playerLevel = levels[player] else { return [] }
        return playerLevel.groups
    }
    
    func player(id: String) -> Player? {
        return self.players.first(where: { $0.id == id })
    }
    
    func toggleIndexSelected(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    // MARK: Private functions
    
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
    
    private func reset() {
        saveJoinCode(nil)
        
        completedLevel = false
        connectedPlayers.removeAll()
        currentPlayer = nil
        currentScreen = .home
        discardPileTopCard = nil
        drawnCard = nil
        gameOver = false
        hand = []
        handCounts = [:]
        hasDrawn = false
        isCreator = false
        isReadyForNextRound = false
        joinCode = nil
        levels = [:]
        newCard = nil
        newCardSelected = false
        players = []
        playersReady.removeAll()
        roundNumber = 1
        roundWinner = nil
        scores = []
        selectedIndices.removeAll()
        table = [:]
        tempTable = [:]
    }
    
    private func saveJoinCode(_ joinCode: String?) {
        UserDefaults.standard.set(joinCode, forKey: joinCodeKey)
    }
    
    // MARK: Notification Handlers
    
    @objc private func onAddToTable(_ notification: Notification) {
        HapticManager.playMediumImpact()
        DispatchQueue.main.async { [self] in
            for index in selectedIndices.sorted(by: { $0 > $1 }) { hand.remove(at: index) }
            if newCardSelected { newCard = nil }
            selectedIndices.removeAll()
            newCardSelected = false
        }
    }
    
    @objc private func onAddToTableError(_ notification: Notification) {
        // TODO: Show an alert if adding to the table fails
    }
    
    @objc private func onCardDrawError(_ notification: Notification) {
        // TODO: Show an alert if drawing a card fails
    }
    
    @objc private func onCreateGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        HapticManager.playMediumImpact()
        saveJoinCode(joinCode)
        
        DispatchQueue.main.async { [self] in
            isCreator = true
            self.joinCode = joinCode
            currentScreen = .lobby
        }
    }
    
    @objc private func onCurrentPlayerUpdate(_ notification: Notification) {
        guard let player = notification.userInfo?["player"] as? String else { return }
        DispatchQueue.main.async { [self] in
            currentPlayer = player
            hasDrawn = false
            
            if isCurrentPlayer { HapticManager.playWarning() }
        }
    }
    
    @objc private func onDiscardTopChange(_ notification: Notification) {
        let discardTop = notification.userInfo?["discardTop"] as? Card
        DispatchQueue.main.async { self.discardPileTopCard = discardTop }
    }
    
    @objc private func onDrawCard(_ notification: Notification) {
        guard let newCard = notification.userInfo?["newCard"] as? Card else { return }
        HapticManager.playMediumImpact()
        DispatchQueue.main.async { [self] in
            drawnCard = newCard
            self.newCard = newCard
            hasDrawn = true
        }
    }
    
    @objc private func onEndGame(_ notification: Notification) {
        DispatchQueue.main.async { self.reset() }
    }
    
    @objc private func onGameCreationError(_ notification: Notification) {
        // TODO: Show an alert if game creation fails
    }
    
    @objc private func onGameOver(_ notification: Notification) {
        guard let winner = notification.userInfo?["roundWinner"] as? Player,
              let scores = notification.userInfo?["scores"] as? [Score]
        else { return }
        
        DispatchQueue.main.async {
            self.gameOver = true
            self.roundWinner = winner
            self.scores = scores.sorted()
            
            if let gameWinner = scores.first?.playerId,
               gameWinner == UserManager.shared.id {
                HapticManager.playSuccess()
            } else {
                HapticManager.playWarning()
            }
        }
    }
    
    @objc private func onGameStart(_ notification: Notification) {
        guard let currentPlayer = notification.userInfo?["currentPlayer"] as? String,
              let discardTop = notification.userInfo?["discardTop"] as? Card,
              let hand = notification.userInfo?["hand"] as? [Card],
              let levels = notification.userInfo?["levels"] as? [String: Level],
              let players = notification.userInfo?["players"] as? [Player]
        else { return }
        
        HapticManager.playWarning()
        let handCounts = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 10) })
        
        DispatchQueue.main.async { [self] in
            completedLevel = false
            self.currentPlayer = currentPlayer
            currentScreen = .game
            discardPileTopCard = discardTop
            gameOver = false
            self.hand = hand.sorted()
            self.handCounts = handCounts
            self.levels = levels
            self.players = players
            playersReady.removeAll()
            roundNumber = 1
            roundWinner = nil
            tempTable = [:]
            table = [:]
        }
    }
    
    @objc private func onGameStateUpdate(_ notification: Notification) {
        guard let currentPlayer = notification.userInfo?["currentPlayer"] as? String,
              let gameOver = notification.userInfo?["gameOver"] as? Bool,
              var hand = notification.userInfo?["hand"] as? [Card],
              let handCounts = notification.userInfo?["handCounts"] as? [String: Int],
              let hasDrawn = notification.userInfo?["hasDrawn"] as? Bool,
              let levels = notification.userInfo?["levels"] as? [String: Level],
              let players = notification.userInfo?["players"] as? [Player],
              let playersReady = notification.userInfo?["playersReady"] as? Set<String>,
              let roundNumber = notification.userInfo?["roundNumber"] as? Int,
              let scores = notification.userInfo?["scores"] as? [Score],
              let table = notification.userInfo?["table"] as? [String: [[Card]]]
        else { return }
        
        let completedLevel = table[UserManager.shared.id!] != nil
        let discardTop = notification.userInfo?["discardTop"] as? Card
        let roundWinner = notification.userInfo?["roundWinner"] as? Player
        
        var newCard: Card?
        if hasDrawn {
            newCard = hand[0]
            hand.remove(at: 0)
        }
        
        hand.sort()
        
        for groupIndex in tempTable.keys {
            for card in tempTable[groupIndex]! {
                if let index = hand.firstIndex(of: card) {
                    hand.remove(at: index)
                }
            }
        }
        
        DispatchQueue.main.async { [self] in
            self.completedLevel = completedLevel
            self.currentPlayer = currentPlayer
            currentScreen = playersReady.contains(UserManager.shared.id ?? "") ? .scoring : .game
            discardPileTopCard = discardTop
            drawnCard = newCard
            self.gameOver = gameOver
            self.hand = hand
            self.handCounts = handCounts
            self.hasDrawn = hasDrawn
            self.levels = levels
            self.newCard = newCard
            self.players = players
            self.playersReady = playersReady
            self.roundNumber = roundNumber
            self.roundWinner = roundWinner
            self.scores = scores.sorted()
            self.table = table
        }
    }
    
    @objc private func onHandCountsUpdated(_ notification: Notification) {
        guard let handCounts = notification.userInfo?["handCounts"] as? [String: Int] else { return }
        DispatchQueue.main.async { self.handCounts = handCounts }
    }
    
    @objc private func onHandUpdate(_ notification: Notification) {
        guard var hand = notification.userInfo?["hand"] as? [Card] else { return }
        for groupIndex in tempTable.keys {
            for card in tempTable[groupIndex]! {
                if let index = hand.firstIndex(of: card) {
                    hand.remove(at: index)
                }
            }
        }
        
        HapticManager.playMediumImpact()
        
        DispatchQueue.main.async { [self] in
            drawnCard = nil
            newCard = nil
            self.hand = hand.sorted()
            selectedIndices.removeAll()
            newCardSelected = false
        }
    }
    
    @objc private func onJoinError(_ notification: Notification) {
        guard let joinError = notification.userInfo?["error"] as? GameConnectError else { return }
        HapticManager.playError()
        print("Error joining game", joinError)
    }
    
    @objc private func onJoinGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        HapticManager.playMediumImpact()
        saveJoinCode(joinCode)
        
        DispatchQueue.main.async { [self] in
            isCreator = false
            self.joinCode = joinCode
            currentScreen = .lobby
        }
    }
    
    @objc private func onLeaveGame(_ notification: Notification) {
        DispatchQueue.main.async { self.reset() }
    }
    
    @objc private func onPlayerListUpdate(_ notification: Notification) {
        guard let players = notification.userInfo?["players"] as? [Player] else { return }
        DispatchQueue.main.async { self.players = players }
    }
    
    @objc private func onPlayersReadyUpdate(_ notification: Notification) {
        guard let playersReady = notification.userInfo?["playersReady"] as? Set<String> else { return }
        if gameOver && playersReady.contains(UserManager.shared.id ?? "") { NetworkManager.shared.endGame() }
        DispatchQueue.main.async { self.playersReady = playersReady }
    }
    
    @objc private func onPresenceUpdate(_ notification: Notification) {
        guard let connectedPlayers = notification.userInfo?["connectedUsers"] as? Set<String> else { return }
        DispatchQueue.main.async { self.connectedPlayers = connectedPlayers }
    }
    
    @objc private func onRoundFinished(_ notification: Notification) {
        guard let winner = notification.userInfo?["winner"] as? Player,
              let scores = notification.userInfo?["scores"] as? [Score]
        else { return }
        
        if completedLevel {
            HapticManager.playSuccess()
        } else {
            HapticManager.playError()
        }
        
        DispatchQueue.main.async { [self] in
            playersReady.removeAll()
            roundWinner = winner
            self.scores = scores.sorted()
        }
    }
    
    @objc private func onRoundStart(_ notification: Notification) {
        guard let currentPlayer = notification.userInfo?["currentPlayer"] as? String,
              let hand = notification.userInfo?["hand"] as? [Card],
              let handCounts = notification.userInfo?["handCounts"] as? [String: Int],
              let levels = notification.userInfo?["levels"] as? [String: Level],
              let roundNumber = notification.userInfo?["roundNumber"] as? Int
        else { return }
        
        HapticManager.playWarning()
        let discardTop = notification.userInfo?["discardTop"] as? Card
        
        DispatchQueue.main.async { [self] in
            self.completedLevel = false
            self.currentPlayer = currentPlayer
            currentScreen = .game
            discardPileTopCard = discardTop
            drawnCard = nil
            self.hand = hand.sorted()
            self.handCounts = handCounts
            hasDrawn = false
            self.levels = levels
            newCard = nil
            newCardSelected = false
            playersReady.removeAll()
            self.roundNumber = roundNumber
            roundWinner = nil
            self.scores = scores.sorted()
            selectedIndices = []
            table = [:]
            tempTable = [:]
        }
    }
    
    @objc private func onSetTable(_ notification: Notification) {
        HapticManager.playSuccess()
        DispatchQueue.main.async {
            self.completedLevel = true
            self.tempTable = [:]
        }
    }
    
    @objc private func onTableUpdate(_ notification: Notification) {
        guard let table = notification.userInfo?["table"] as? [String: [[Card]]] else { return }
        DispatchQueue.main.async { self.table = table }
    }
}
