//
//  GameViewModel.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var connectedPlayers = Set<String>()
    @Published var currentPlayer: String?
    @Published var currentScreen = Screen.home
    @Published var discardPileTopCard: Card?
    @Published var error: String?
    @Published var gameOver = false
    @Published var hand: [Card] = []
    @Published var handCounts: [String: Int] = [:]
    @Published var newCard: Card?
    @Published var newCardSelected = false
    @Published var players: [Player] = []
    @Published var playersReady = Set<String>()
    @Published var remainingPlayers = Set<String>()
    @Published var roundWinner: Player?
    @Published var selectedIndices = Set<Int>()
    @Published var selectPlayerToSkip = false
    @Published var showLeaveModal = false
    @Published var table: [String: [[Card]]] = [:]
    @Published var tempTable: [Int: [Card]] = [:]
    @Published var unsupportedVersion = false
    @Published var waitingOnAction = false
    
    var completedLevel = false
    var drawnCard: Card?
    var hasDrawn = false
    var isCreator = false
    var isReadyForNextRound = false
    var joinCode: String?
    var levels: [String: Level] = [:]
    var roundNumber = 1
    var scores: [Score] = []
    var settings = GameSettings(skipNextPlayer: false)
    var skippedPlayers = Set<String>()
    
    var isCurrentPlayer: Bool {
        return UserManager.shared.id == currentPlayer
    }
    
    var inviteUrl: String {
        var configuration = Configuration()
        guard let joinCode = joinCode else { return configuration.environment.apiBaseUrl }
        return "\(configuration.environment.apiBaseUrl)/join/\(joinCode)"
    }
    
    var scoresOrDefault: [Score] {
        guard scores.isEmpty else { return scores }
        return players.map { Score(level: 1, playerId: $0.id, points: 0) }
    }
    
    var selectedCards: [Card] {
        var cards = [Card]()
        for index in selectedIndices { cards.append(hand[index]) }
        if let newCard = newCard, newCardSelected { cards.append(newCard) }
        return cards
    }
    
    var skippablePlayers: Set<String> {
        let ids = players
            .map { $0.id }
            .filter { $0 != UserManager.shared.id && !skippedPlayers.contains($0) }
        
        return Set(ids)
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
        NotificationCenter.default.addObserver(self, selector: #selector(onDiscardError), name: .didReceiveDiscardError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameCreationError), name: .didReceiveGameCreationError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStateUpdate), name: .didReceiveGameState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayersReadyUpdate), name: .didReceivePlayersReadyUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate), name: .didReceivePresenceUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandCountsUpdated), name: .didReceiveUpdatedHandCounts, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerListUpdate), name: .didReceiveUpdatedPlayerList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerRemoved), name: .didRemovePlayer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSetTable), name: .didSetTable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDiscardTopChange), name: .discardTopDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameOver), name: .gameDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameStart), name: .gameDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJoinError), name: .gameJoinError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHandUpdate), name: .handDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRoundFinished), name: .roundDidFinish, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRoundStart), name: .roundDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onSkippedPlayersUpdated), name: .skippedPlayersDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTableUpdate), name: .tableDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onVersionUnsupported), name: .versionUnsupported, object: nil)
        
        checkUnsupportedVersion()
        maybeConnectToExistingGame()
    }
    
    func addToPlayerTable(playerId: String, index: Int) {
        guard completedLevel else {
            withAnimation { error = "Finish up your own level before you worry about others 🤓" }
            return
        }
        
        guard let playerTable = table[playerId], playerTable.count > index else {
            withAnimation { error = "You can only play off others' hands once they've finished the level 😅" }
            return
        }
        
        HapticManager.playMediumImpact()
        
        Task {
            try? await NetworkManager.shared.addToTable(cards: self.selectedCards, tablePlayerId: playerId, groupPosition: index)
        }
    }
    
    func addToTable(_ index: Int) {
        let level = levels[UserManager.shared.id!]!
        let levelGroup = level.groups[index]
        guard levelGroup.isValid(selectedCards) else {
            withAnimation { error = "That's not a \(levelGroup.toString().lowercased()) 🤨" }
            return
        }
        
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
    
    func handleUrlPathComponents(_ pathComponents: [String]) {
        // TODO: Let the user leave the current game when a link is opened
        guard players.count == 0 else { return }
        
        guard pathComponents.count > 1 else {
            currentScreen = .home
            return
        }
        
        switch pathComponents[1] {
        case "create":
            currentScreen = .create
        case "join":
            currentScreen = .join
            if pathComponents.count > 2 { joinCode = pathComponents[2] }
        default:
            currentScreen = .home
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
    
    func skipPlayer(id playerId: String) {
        if !settings.skipNextPlayer,
           skippablePlayers.contains(playerId),
           selectedCards.count == 1,
           let card = selectedCards.first,
           card.value == .skip {
            Task {
                do {
                    try await NetworkManager.shared.discardCard(card: card, playerToSkip: playerId)
                } catch {
                    print("Error received when skipping player", error)
                }
            }
        } else {
            print("Could not specify player to skip")
        }
    }
    
    func toggleIndexSelected(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
    
    // MARK: Private functions
    
    private func checkUnsupportedVersion() {
        var configuration = Configuration()
        let key = configuration.environment.unsupportedVersionKey
        if let unsupportedVersionNumber = UserDefaults.standard.string(forKey: key) {
            if unsupportedVersionNumber == Bundle.main.appVersion {
                unsupportedVersion = true
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    private func maybeConnectToExistingGame() {
        if !unsupportedVersion,
           let joinCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.joinCodeKey) {
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
        remainingPlayers.removeAll()
        roundNumber = 1
        roundWinner = nil
        scores = []
        selectedIndices.removeAll()
        selectPlayerToSkip = false
        settings = GameSettings(skipNextPlayer: false)
        showLeaveModal = false
        skippedPlayers.removeAll()
        table = [:]
        tempTable = [:]
        waitingOnAction = false
    }
    
    private func saveJoinCode(_ joinCode: String?) {
        UserDefaults.standard.set(joinCode, forKey: UserDefaultsKeys.joinCodeKey)
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
        guard let error = notification.userInfo?["error"] as? AddToTableError else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var message: String
            
            switch error {
            case .invalidGroup:
                message = "Those cards don't match the group silly 😋"
            case .levelIncomplete:
                message = "Finish up your own level before you worry about others 🤓"
            case .needsToDraw:
                message = "You need to draw before you can do that 😂"
            case .notYourTurn:
                message = "Watch it bud! It's not your turn yet 😠"
            case .unrecognized(_):
                message = "An unexpected error occurred. Please try force quitting the app and then try again 🤯"
            }
            
            withAnimation { self.error = message }
        }
    }
    
    @objc private func onCardDrawError(_ notification: Notification) {
        guard let error = notification.userInfo?["error"] as? CardDrawError else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var message: String
            
            switch error {
            case .alreadyDrawn:
                message = "You can't draw twice in the same turn silly 😋"
            case .emptyDiscardPile:
                message = "What are you trying to draw? The discard pile is empty... 🕵️‍♂️"
            case .notYourTurn:
                message = "Watch it bud! It's not your turn yet 😠"
            case .skip:
                message = "You can't draw a skip that has already been discarded 😂"
            case .unrecognized(_):
                message = "An unexpected error occurred. Please try force quitting the app and then try again 🤯"
            }
            
            withAnimation { self.error = message }
        }
    }
    
    @objc private func onCreateGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        HapticManager.playMediumImpact()
        saveJoinCode(joinCode)
        NotificationManager.shared.registerForPushNotifications()
        
        DispatchQueue.main.async { [self] in
            isCreator = true
            self.joinCode = joinCode
            currentScreen = .lobby
            waitingOnAction = false
        }
    }
    
    @objc private func onCurrentPlayerUpdate(_ notification: Notification) {
        guard let player = notification.userInfo?["player"] as? String else { return }
        DispatchQueue.main.async { [self] in
            currentPlayer = player
            hasDrawn = false
            
            if isCurrentPlayer {
                HapticManager.playWarning()
                SoundManager.shared.playNotify()
            }
        }
    }
    
    @objc private func onDiscardError(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let error = notification.userInfo?["error"] as? DiscardError
            else { return }
            
            var message: String
            switch error {
            case .alreadySkipped:
                message = "They were already skipped... Continue that vendetta on your next turn instead 😈"
            case .chooseSkipTarget:
                message = "I'm not sure what you just did, but I don't like it 🤨"
            case .needsToDraw:
                message = "You can't discard when you haven't drawn yet 🤓"
            case .noCard:
                message = "You need to select a card in your hand before you can discard it silly 😄"
            case .notYourTurn:
                message = "What are you up to? You can't discard when it's not your turn... 🕵️‍♂️"
            case .unrecognized(_):
                message = "I'm not sure what you just did, but I don't like it 🤨"
            }
            
            withAnimation { self.error = message }
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
        HapticManager.playError()
        DispatchQueue.main.async {
            self.waitingOnAction = false
            
            guard let error = notification.userInfo?["error"] as? GameCreationError else { return }
            
            withAnimation {
                switch error {
                case .networkError:
                    self.error = "The network connection exploded, and couldn't connect to the created game. Please force quit the app and try again 🤯"
                case .serverError:
                    self.error = "Our servers exploded, and the game couldn't be created. Please try again later 🤯"
                }
            }
        }
    }
    
    @objc private func onGameOver(_ notification: Notification) {
        guard let payload = notification.userInfo?["payload"] as? GameFinishedPayload else { return }
        
        DispatchQueue.main.async {
            self.gameOver = true
            withAnimation { self.roundWinner = payload.roundWinner }
            self.scores = payload.scores.sorted()
            
            if let gameWinner = self.scores.first?.playerId,
               gameWinner == UserManager.shared.id {
                HapticManager.playSuccess()
                SoundManager.shared.playSuccess()
            } else {
                HapticManager.playWarning()
                SoundManager.shared.playFailure()
            }
        }
    }
    
    @objc private func onGameStart(_ notification: Notification) {
        guard let game = notification.userInfo?["game"] as? Game else { return }
        
        HapticManager.playWarning()
        SoundManager.shared.playNotify()
        let handCounts = Dictionary(uniqueKeysWithValues: game.players.map { ($0.id, 10) })
        let remainingPlayers = Set(players.map { $0.id })
        
        DispatchQueue.main.async { [self] in
            completedLevel = false
            self.currentPlayer = game.currentPlayer
            currentScreen = .game
            discardPileTopCard = game.discardTop
            gameOver = false
            self.hand = game.hand.sorted()
            self.handCounts = handCounts
            self.levels = game.levels
            self.players = game.players
            playersReady.removeAll()
            self.remainingPlayers = remainingPlayers
            roundNumber = 1
            roundWinner = nil
            selectPlayerToSkip = false
            self.settings = game.settings
            skippedPlayers.removeAll()
            tempTable = [:]
            table = [:]
            waitingOnAction = false
        }
    }
    
    @objc private func onGameStateUpdate(_ notification: Notification) {
        guard var game = notification.userInfo?["game"] as? Game,
              let handCounts = game.handCounts,
              let remainingPlayers = game.remainingPlayers,
              let roundNumber = game.roundNumber,
              let scores = game.scores,
              let table = game.table
        else { return }
        
        let hasDrawn = game.hasDrawn ?? false
        var newCard: Card?
        if game.hasDrawn ?? false {
            newCard = game.hand[0]
            game.hand.remove(at: 0)
        }
        
        game.hand.sort()
        
        for groupIndex in tempTable.keys {
            for card in tempTable[groupIndex]! {
                if let index = game.hand.firstIndex(of: card) {
                    game.hand.remove(at: index)
                }
            }
        }
        
        DispatchQueue.main.async { [self] in
            completedLevel = table[UserManager.shared.id!] != nil
            currentPlayer = game.currentPlayer
            currentScreen = playersReady.contains(UserManager.shared.id ?? "") ? .scoring : .game
            discardPileTopCard = game.discardTop
            drawnCard = newCard
            gameOver = game.gameOver ?? false
            hand = game.hand
            self.handCounts = handCounts
            self.hasDrawn = hasDrawn
            levels = game.levels
            self.newCard = newCard
            players = game.players
            playersReady = game.playersReady ?? []
            self.remainingPlayers = remainingPlayers
            self.roundNumber = roundNumber
            withAnimation { self.roundWinner = game.roundWinner }
            self.scores = scores.sorted()
            selectPlayerToSkip = false
            settings = game.settings
            skippedPlayers = game.skippedPlayers ?? []
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.waitingOnAction = false
            
            withAnimation {
                switch joinError {
                case .alreadyStarted:
                    self.error = "The game you're trying to join has already started. Looks like you need some new friends 😬"
                case .full:
                    self.error = "That game is already full. Looks like you were the slow one in the group 😩"
                case .notFound:
                    self.error = "That join code doesn't exist. Are you trying to hack us? 🤨"
                case .unknownError(let errorString):
                    self.error = "An unexpected error occurred: \(errorString)"
                }
            }
        }
    }
    
    @objc private func onJoinGame(_ notification: Notification) {
        guard let joinCode = notification.userInfo?["joinCode"] as? String else { return }
        HapticManager.playMediumImpact()
        saveJoinCode(joinCode)
        NotificationManager.shared.registerForPushNotifications()
        
        DispatchQueue.main.async { [self] in
            isCreator = false
            self.joinCode = joinCode
            currentScreen = .lobby
            waitingOnAction = false
        }
    }
    
    @objc private func onLeaveGame(_ notification: Notification) {
        DispatchQueue.main.async { self.reset() }
    }
    
    @objc private func onPlayerListUpdate(_ notification: Notification) {
        guard let players = notification.userInfo?["players"] as? [Player] else { return }
        DispatchQueue.main.async { self.players = players }
    }
    
    @objc private func onPlayerRemoved(_ notification: Notification) {
        guard let playerId = notification.userInfo?["player"] as? String else { return }
        DispatchQueue.main.async { self.remainingPlayers.remove(playerId) }
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
        guard let payload = notification.userInfo?["payload"] as? RoundFinishedPayload else { return }
        
        if completedLevel {
            HapticManager.playSuccess()
            SoundManager.shared.playSuccess()
        } else {
            HapticManager.playError()
            SoundManager.shared.playFailure()
        }
        
        DispatchQueue.main.async { [self] in
            playersReady.removeAll()
            withAnimation { roundWinner = payload.winner }
            self.scores = payload.scores.sorted()
        }
    }
    
    @objc private func onRoundStart(_ notification: Notification) {
        guard let payload = notification.userInfo?["payload"] as? RoundStartPayload else { return }
        
        HapticManager.playWarning()
        SoundManager.shared.playNotify()
        
        DispatchQueue.main.async { [self] in
            completedLevel = false
            currentPlayer = payload.currentPlayer
            currentScreen = .game
            discardPileTopCard = payload.discardTop
            drawnCard = nil
            hand = payload.hand.sorted()
            handCounts = payload.handCounts
            hasDrawn = false
            levels = payload.levels
            newCard = nil
            newCardSelected = false
            playersReady.removeAll()
            remainingPlayers = payload.remainingPlayers
            roundNumber = payload.roundNumber
            roundWinner = nil
            selectedIndices = []
            selectPlayerToSkip = false
            settings = payload.settings
            skippedPlayers.removeAll()
            table = [:]
            tempTable = [:]
        }
    }
    
    @objc private func onSetTable(_ notification: Notification) {
        HapticManager.playSuccess()
        SoundManager.shared.playSuccess()
        DispatchQueue.main.async {
            self.completedLevel = true
            self.tempTable = [:]
        }
    }
    
    @objc private func onSkippedPlayersUpdated(_ notification: Notification) {
        if let skippedPlayers = notification.userInfo?["skippedPlayers"] as? Set<String> {
            self.skippedPlayers = skippedPlayers
        }
    }
    
    @objc private func onTableUpdate(_ notification: Notification) {
        guard let table = notification.userInfo?["table"] as? [String: [[Card]]] else { return }
        DispatchQueue.main.async { self.table = table }
    }
    
    @objc private func onVersionUnsupported(_ notification: Notification) {
        DispatchQueue.main.async { self.unsupportedVersion = true }
        var configuration = Configuration()
        UserDefaults.standard.set(Bundle.main.appVersion, forKey: configuration.environment.unsupportedVersionKey)
    }
}
