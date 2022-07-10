//
//  NetworkManager.swift
//  Level10
//
//  Created by Dennis Beatty on 5/20/22.
//

import Foundation
import os
import SwiftPhoenixClient

struct User: Codable {
    let id: String
    let token: String
}

enum GameConnectError: Error {
    case alreadyStarted
    case full
    case notFound
    case unknownError(String)
}

enum NetworkError: Error {
    case badRequest
    case badServerResponse
    case badURL
    case channelNotJoined
    case notFound
    case requestRateLimited
    case requestForbidden
    case requestUnauthorized
    case socketNotConnected
    case unknownError
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NetworkManager")
    private let createdGameConnectMaxAttempts = 6
    
    private var authToken: String?
    private var lobbyChannel: Channel?
    private var gameChannel: Channel?
    private var socket: Socket?
    private var presence: Presence?
    private var sentDeviceToken = false
    
    private init() {
        var configuration = Configuration()
        socket = Socket("\(configuration.environment.socketBaseUrl)/socket/websocket", paramsClosure: { [weak self] in
            guard let self = self, let authToken = self.authToken else { return [:] }
            var params = ["token": authToken]
            
            if let deviceToken = NotificationManager.shared.deviceToken {
                params["device"] = deviceToken
                self.sentDeviceToken = true
            } else {
                print("No device token found")
            }
            
            return params
        })
        
        guard let socket = socket else { return }
        lobbyChannel = socket.channel("game:lobby")
        socket.onOpen { print("Socket opened") }
        socket.onClose { print("Socket closed") }
        socket.onError { error in
            if let error = error as? URLError {
                switch error.code {
                case .badServerResponse:
                    // This response is returned whenever the server denies the connection.
                    // This is usually because the auth token is invalid.
                    print("Server denied connection")
                    UserManager.shared.refreshToken()
                default:
                    print("Error \(error.code): \(error.localizedDescription)")
                    NotificationCenter.default.post(name: .connectionDidFail, object: nil, userInfo: ["error": error])
                }
            }
        }
//        socket.logger = { message in print("LOG:", message) }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSetToken), name: .didSetToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewDeviceToken), name: .didRegisterDeviceToken, object: nil)
    }
    
    /**
     Adds cards from the player's hand to one of the places on the table.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func addToTable(cards: [Card], tablePlayerId: String, groupPosition: Int) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        
        let cardDicts = cards.map { $0.forJson() }
        
        channel
            .push("add_to_table", payload: ["cards": cardDicts, "player_id": tablePlayerId, "position": groupPosition])
            .receive("ok") { _ in
                NotificationCenter.default.post(name: .didAddToTable, object: nil)
            }
            .receive("error") { response in
                NotificationCenter.default.post(name: .didReceiveAddToTableError, object: nil, userInfo: ["error": response.payload["response"] ?? ""])
            }
    }
    
    /**
     Establish connection with the websocket server and join the lobby channel.
     */
    func connectSocket() async {
        guard let socket = socket, let channel = lobbyChannel, !socket.isConnected else { return }
        do {
            authToken = try await UserManager.shared.getToken()
            socket.connect()
            
            channel
                .join()
                .receive("ok") { message in print("Lobby joined", message.payload)}
                .receive("error") { message in print("Failed to join lobby", message.payload)}
        } catch {
            print("Error connecting to socket: ", error)
        }
    }
    
    /**
     Create a new game on the server.
     
     - Parameter withDisplayName: The name to display for the user creating the game.
     - Parameter settings: Settings to use for the game being created.
     
     - Throws: `NetworkError.socketNotConnected` or `NetworkError.channelNotJoined` if either the socket or the lobby channel was not connected properly.
     */
    func createGame(withDisplayName name: String, settings: GameSettings) async throws {
        guard let socket = socket else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        guard let channel = lobbyChannel else { throw NetworkError.channelNotJoined }
        
        let params: [String: Any] = ["displayName": name, "skipNextPlayer": settings.skipNextPlayer]
        
        channel
            .push("create_game", payload: params)
            .receive("ok") { response in
                guard let joinCode = response.payload["joinCode"] as? String else { return }
                self.connectToCreatedGame(joinCode: joinCode, remainingAttempts: self.createdGameConnectMaxAttempts)
            }
            .receive("error") { response in
                NotificationCenter.default.post(name: .didReceiveGameCreationError, object: nil, userInfo: ["error": response.payload["response"] ?? ""])
            }
    }
    
    /**
     Create a new user id and token combination.
     
     - Returns: `User` with an ID and token to be used for future requests.
     
     - Throws:
        - `NetworkError.badRequest` when the server returns a 400 response.
        - `NetworkError.requestUnauthorized` when the server returns a 401 response.
        - `NetworkError.requestForbidden` when the server returns a 403 response.
        - `NetworkError.notFound` when the server returns a 404 response.
        - `NetworkError.requestRateLimited` when the server returns a 429 response.
        - `NetworkError.badServerResponse` when the server returns a 500-level response, or anything unrecognized.
     */
    func createUser() async throws -> User {
        var configuration = Configuration()
        let url = URL(string: "\(configuration.environment.apiBaseUrl)/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.badServerResponse }
        
        switch httpResponse.statusCode {
        case 200:
            let decodedUser = try JSONDecoder().decode(User.self, from: data)
            return decodedUser
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.requestUnauthorized
        case 403:
            throw NetworkError.requestForbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.requestRateLimited
        default:
            self.logger.warning("Unexpected status code: \(httpResponse.allHeaderFields)")
            throw NetworkError.badServerResponse
        }
    }
    
    /**
     Discards a card from the player's hand.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func discardCard(card: Card, playerToSkip: String?) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        var payload: [String: Any] = ["card": card.forJson()]
        if let playerToSkip = playerToSkip { payload["player_id"] = playerToSkip }
        
        channel
            .push("discard", payload: payload)
            .receive("ok") { [weak self] response in
                guard let self = self,
                      let handDicts = response.payload["hand"] as? [[String: String]]
                else { return }
                
                let hand = handDicts.compactMap(self.cardFromDict)
                NotificationCenter.default.post(name: .handDidUpdate, object: nil, userInfo: ["hand": hand])
            }
            .receive("error") { response in
                NotificationCenter.default.post(name: .didReceiveDiscardError, object: nil, userInfo: ["error": response.payload["response"] ?? ""])
            }
    }
    
    /**
     Draws a card from either the draw pile or the discard pile.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func drawCard(source: DrawSource) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        let params: [String: Any] = ["source": source.rawValue]
        
        channel
            .push("draw_card", payload: params)
            .receive("ok") { [weak self] response in
                guard let self = self,
                      let newCardDict = response.payload["card"] as? [String: String],
                      let newCard = self.cardFromDict(newCardDict)
                else { return }
                
                NotificationCenter.default.post(name: .didDrawCard, object: nil, userInfo: ["newCard": newCard])
            }
            .receive("error") { response in
                NotificationCenter.default.post(name: .didReceiveCardDrawError, object: nil, userInfo: ["error": response.payload["response"] ?? ""])
            }
    }
    
    func endGame() {
        gameChannel?.leave()
        gameChannel = nil
        NotificationCenter.default.post(name: .didEndGame, object: nil)
    }
    
    /**
     Join an existing game on the server.
     
     - Parameter withCode: The join code for the game to join.
     - Parameter displayName: The name to display for the user creating the game.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func joinGame(withCode joinCode: String, displayName name: String) async throws {
        guard let socket = socket else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        self.connectToGame(joinCode: joinCode, params: ["displayName": name]) { error in
            if let error = error {
                NotificationCenter.default.post(name: .gameJoinError, object: nil, userInfo: ["error": error])
            } else {
                NotificationCenter.default.post(name: .didJoinGame, object: nil, userInfo: ["joinCode": joinCode])
            }
        }
    }
    
    /**
     Leaves the game after it has started.
     */
    func leaveGame() {
        gameChannel?.push("leave_game", payload: [:])
        gameChannel?.leave()
        gameChannel = nil
        sentDeviceToken = false
        NotificationCenter.default.post(name: .didLeaveGame, object: nil)
    }
    
    /**
     Leaves the game while still in the lobby.
     */
    func leaveLobby() {
        gameChannel?.push("leave_lobby", payload: [:])
        gameChannel?.leave()
        gameChannel = nil
        sentDeviceToken = false
        NotificationCenter.default.post(name: .didLeaveGame, object: nil)
    }
    
    /**
     Marks the player as ready to start the next round.
     */
    func markReady() {
        gameChannel?.push("mark_ready", payload: [:])
    }
    
    /**
     Reconnect to a game that the player has already created or joined.
     
     - Parameter withCode: The join code for the game to which connection should be re-established.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func reconnectToGame(withCode joinCode: String) async throws {
        guard let socket = socket else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        self.connectToGame(joinCode: "game:\(joinCode)", completionHandler: nil)
    }
    
    /**
     Sends the device's token to the server to allow for push notifications to be received.
     */
    func sendDeviceTokenToServer() {
        if let gameChannel = gameChannel, let deviceToken = NotificationManager.shared.deviceToken {
            gameChannel
                .push("put_device_token", payload: ["token": deviceToken])
                .receive("ok") { [weak self] _ in
                    self?.sentDeviceToken = true
            }
        }
    }
    
    /**
     Starts a game. Expects the player sending the message to be the player who created the game.
     */
    func startGame() {
        gameChannel?.push("start_game", payload: [:])
    }
    
    /**
     Adds cards from the player's hand to their table.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func tableCards(table: [[Card]]) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        
        let tableGroups = table.map { group in
            group.compactMap { $0.forJson() }
        }
        
        channel
            .push("table_cards", payload: ["table": tableGroups])
            .receive("ok") { _ in
                NotificationCenter.default.post(name: .didSetTable, object: nil)
            }
            .receive("error") { response in
                print("Table set error: ", response.payload["response"] ?? "")
                NotificationCenter.default.post(name: .didReceiveTableSetError, object: nil, userInfo: ["error": response.payload["response"] ?? ""])
            }
    }
    
    // MARK: Private functions
    
    private func connectDelay(for n: Int) -> Int {
        let maxDelay = 3200
        let delay = Int(pow(2.0, Double(n))) * 100
        let jitter = Int.random(in: 0...100)
        return min(delay + jitter, maxDelay)
    }
    
    private func connectToCreatedGame(joinCode: String, remainingAttempts: Int) {
        guard socket != nil else {
            NotificationCenter.default.post(name: .didReceiveGameCreationError, object: nil, userInfo: ["error": "socket error"])
            return
        }
        
        let attemptNumber = self.createdGameConnectMaxAttempts - remainingAttempts
        print("Attempting to connect to created game. This is attempt number \(attemptNumber)")
        
        self.connectToGame(joinCode: joinCode) { error in
            if let error = error {
                if case .notFound = error, remainingAttempts > 0 {
                    let delay = self.connectDelay(for: self.createdGameConnectMaxAttempts - remainingAttempts)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay)) {
                        self.connectToCreatedGame(joinCode: joinCode, remainingAttempts: remainingAttempts - 1)
                    }
                    return
                    
                } else {
                    print("Error connecting to created game", error)
                    return
                }
            }
            
            NotificationCenter.default.post(name: .didCreateGame, object: nil, userInfo: ["joinCode": joinCode])
        }
    }
    
    private func connectToGame(joinCode: String, completionHandler: ((GameConnectError?) -> Void)?) {
        connectToGame(joinCode: joinCode, params: [:], completionHandler: completionHandler)
    }
    
    private func connectToGame(joinCode: String, params: [String: String], completionHandler: ((GameConnectError?) -> Void)?) {
        guard let socket = socket else { return }
        self.gameChannel = socket.channel("game:\(joinCode)", params: params)
        guard let gameChannel = gameChannel else { return }
        
        presence = Presence(channel: gameChannel)
        presence!.onSync {
            let connectedUsers = Set(self.presence!.state.keys)
            NotificationCenter.default.post(name: .didReceivePresenceUpdate, object: nil, userInfo: ["connectedUsers": connectedUsers])
        }
        
        gameChannel.on("game_finished") { [weak self] message in
            guard let self = self,
                  let scoreDicts = message.payload["scores"] as? [[String: Any]],
                  let winnerDict = message.payload["round_winner"] as? [String: String],
                  let winner = self.playerFromDict(winnerDict)
            else { return }
            
            let scores = scoreDicts.compactMap(self.scoreFromDict)
            NotificationCenter.default.post(name: .gameDidFinish, object: nil, userInfo: ["scores": scores, "roundWinner": winner])
        }
        
        gameChannel.on("game_started") { [weak self] message in
            guard let self = self,
                  let currentPlayer = message.payload["current_player"] as? String,
                  let discardTopDict = message.payload["discard_top"] as? [String: String],
                  let discardTop = self.cardFromDict(discardTopDict),
                  let handDicts = message.payload["hand"] as? [[String: String]],
                  let levelDicts = message.payload["levels"] as? [String: [[String: Any]]],
                  let playerDicts = message.payload["players"] as? [[String: String]],
                  let skipNextPlayer = message.payload["skip_next_player"] as? Bool
            else { return }
            
            let hand = handDicts.compactMap(self.cardFromDict)
            let levels = self.levelsFromDict(levelDicts)
            
            let players: [Player] = playerDicts.compactMap { dict in
                guard let name = dict["name"], let id = dict["id"] else { return nil }
                return Player(name: name, id: id)
            }
            
            let info: [AnyHashable: Any] = [
                "currentPlayer": currentPlayer,
                "discardTop": discardTop,
                "hand": hand,
                "levels": levels,
                "players": players,
                "settings": GameSettings(skipNextPlayer: skipNextPlayer)
            ]
            
            NotificationCenter.default.post(name: .gameDidStart, object: nil, userInfo: info)
        }
        
        gameChannel.on("hand_counts_updated") { message in
            guard let handCounts = message.payload["hand_counts"] as? [String: Int] else { return }
            NotificationCenter.default.post(name: .didReceiveUpdatedHandCounts, object: nil, userInfo: ["handCounts": handCounts])
        }
        
        gameChannel.on("latest_state") { [weak self] message in
            guard let self = self,
                  let currentPlayer = message.payload["current_player"] as? String,
                  let gameOver = message.payload["game_over"] as? Bool,
                  let handCounts = message.payload["hand_counts"] as? [String: Int],
                  let handDicts = message.payload["hand"] as? [[String: String]],
                  let hasDrawn = message.payload["has_drawn"] as? Bool,
                  let levelDicts = message.payload["levels"] as? [String: [[String: Any]]],
                  let playerDicts = message.payload["players"] as? [[String: String]],
                  let remainingPlayers = message.payload["remaining_players"] as? [String],
                  let roundNumber = message.payload["round_number"] as? Int,
                  let skipNextPlayer = message.payload["skip_next_player"] as? Bool,
                  let tableDicts = message.payload["table"] as? [String: [[[String: String]]]]
            else { return }
            
            let discardTopDict = message.payload["discard_top"] as? [String: String]
            let playersReady = message.payload["players_ready"] as? [String] ?? []
            let roundWinnerDict = message.payload["round_winner"] as? [String: String]
            let scoreDicts = message.payload["scores"] as? [[String: Any]]
            let skippedPlayers = message.payload["skipped_players"] as? [String] ?? []
            
            // Convert the various dictionaries to card, level, player, and score structs
            let hand = handDicts.compactMap(self.cardFromDict)
            let levels = self.levelsFromDict(levelDicts)
            let scores = scoreDicts?.compactMap(self.scoreFromDict) ?? []
            
            let players: [Player] = playerDicts.compactMap(self.playerFromDict)
            
            var table: [String: [[Card]]] = [:]
            for playerId in tableDicts.keys {
                var playerTable: [[Card]] = []
                
                for group in tableDicts[playerId]! {
                    let cards = group.compactMap(self.cardFromDict)
                    playerTable.append(cards)
                }
                
                table[playerId] = playerTable
            }
            
            // Broadcast the latest state
            var info: [AnyHashable: Any] = [
                "currentPlayer": currentPlayer,
                "gameOver": gameOver,
                "hand": hand,
                "handCounts": handCounts,
                "hasDrawn": hasDrawn,
                "levels": levels,
                "players": players,
                "playersReady": Set(playersReady),
                "remainingPlayers": Set(remainingPlayers),
                "roundNumber": roundNumber,
                "scores": scores,
                "settings": GameSettings(skipNextPlayer: skipNextPlayer),
                "skippedPlayers": Set(skippedPlayers),
                "table": table
            ]
            
            if let discardTopDict = discardTopDict { info["discardTop"] = self.cardFromDict(discardTopDict) }
            if let roundWinnerDict = roundWinnerDict { info["roundWinner"] = self.playerFromDict(roundWinnerDict) }
            
            NotificationCenter.default.post(name: .didReceiveGameState, object: nil, userInfo: info)
        }
        
        gameChannel.on("new_discard_top") { [weak self] message in
            guard let self = self else { return }
            
            let cardDict = message.payload["discard_top"] as? [String: String]
            let userInfo: [AnyHashable: Any] = cardDict == nil ? [:] : ["discardTop": self.cardFromDict(cardDict!)!]
            
            NotificationCenter.default.post(name: .discardTopDidChange, object: nil, userInfo: userInfo)
        }
        
        gameChannel.on("new_turn") { message in
            guard let player = message.payload["player"] as? String else { return }
            NotificationCenter.default.post(name: .currentPlayerDidUpdate, object: nil, userInfo: ["player": player])
        }
        
        gameChannel.on("player_removed") { message in
            guard let playerId = message.payload["player"] as? String else { return }
            NotificationCenter.default.post(name: .didRemovePlayer, object: nil, userInfo: ["player": playerId])
        }
        
        gameChannel.on("players_ready") { message in
            guard let playersReady = message.payload["players"] as? [String] else { return }
            NotificationCenter.default.post(name: .didReceivePlayersReadyUpdate, object: nil, userInfo: ["playersReady": Set(playersReady)])
        }
        
        gameChannel.on("players_updated") { [weak self] message in
            guard let self = self,
                  let playerDicts = message.payload["players"] as? [[String: String]]
            else { return }
            
            let players: [Player] = playerDicts.compactMap(self.playerFromDict)
            NotificationCenter.default.post(name: .didReceiveUpdatedPlayerList, object: nil, userInfo: ["players": players])
        }
        
        gameChannel.on("round_finished") { [weak self] message in
            guard let self = self,
                  let scoreDicts = message.payload["scores"] as? [[String: Any]],
                  let winnerDict = message.payload["winner"] as? [String: String],
                  let winner = self.playerFromDict(winnerDict)
            else { return }
            
            let scores = scoreDicts.compactMap(self.scoreFromDict)
            NotificationCenter.default.post(name: .roundDidFinish, object: nil, userInfo: ["scores": scores, "winner": winner])
        }
        
        gameChannel.on("round_started") { [weak self] message in
            guard let self = self,
                  let currentPlayer = message.payload["current_player"] as? String,
                  let handCounts = message.payload["hand_counts"] as? [String: Int],
                  let handDicts = message.payload["hand"] as? [[String: String]],
                  let levelDicts = message.payload["levels"] as? [String: [[String: Any]]],
                  let remainingPlayers = message.payload["remaining_players"] as? [String],
                  let roundNumber = message.payload["round_number"] as? Int,
                  let skipNextPlayer = message.payload["skip_next_player"] as? Bool
            else { return }
            
            let discardTopDict = message.payload["discard_top"] as? [String: String]
            let hand = handDicts.compactMap(self.cardFromDict)
            let levels = self.levelsFromDict(levelDicts)
            
            var info: [AnyHashable: Any] = [
                "currentPlayer": currentPlayer,
                "hand": hand,
                "handCounts": handCounts,
                "levels": levels,
                "remainingPlayers": Set(remainingPlayers),
                "roundNumber": roundNumber,
                "settings": GameSettings(skipNextPlayer: skipNextPlayer)
            ]
            
            if let discardTopDict = discardTopDict { info["discardTop"] = self.cardFromDict(discardTopDict) }
            
            NotificationCenter.default.post(name: .roundDidStart, object: nil, userInfo: info)
        }
        
        gameChannel.on("skipped_players_updated") { message in
            guard let skippedPlayers = message.payload["skipped_players"] as? [String] else { return }
            NotificationCenter.default.post(name: .skippedPlayersDidUpdate, object: nil, userInfo: ["skippedPlayers": Set(skippedPlayers)])
        }
        
        gameChannel.on("table_updated") { [weak self] message in
            guard let self = self,
                  let tableDicts = message.payload["table"] as? [String: [[[String: String]]]]
            else { return }
            
            var table: [String: [[Card]]] = [:]
            for playerId in tableDicts.keys {
                var playerTable: [[Card]] = []
                
                for group in tableDicts[playerId]! {
                    let cards = group.compactMap(self.cardFromDict)
                    playerTable.append(cards)
                }
                
                table[playerId] = playerTable
            }
            
            NotificationCenter.default.post(name: .tableDidUpdate, object: nil, userInfo: ["table": table])
        }
        
        gameChannel
            .join()
            .receive("ok") { [weak self] message in
                print("Connected to game", message.payload)
                
                if let self = self, !self.sentDeviceToken, NotificationManager.shared.deviceToken != nil {
                    self.sendDeviceTokenToServer()
                }
                
                if let completionHandler = completionHandler { completionHandler(nil) }
            }
            .receive("error") { [weak self] message in
                guard let self = self else { return }
                gameChannel.leave()
                self.gameChannel = nil
                
                if let completionHandler = completionHandler,
                   let reason = message.payload["reason"] as? String {
                    switch reason {
                    case "Game has already started":
                        completionHandler(.alreadyStarted)
                    case "Game is full":
                        completionHandler(.full)
                    case "Game not found":
                        completionHandler(.notFound)
                    default:
                        print("Failed to connect to game for unrecognized reason:", reason)
                        completionHandler(.unknownError(reason))
                    }
                }
            }
    }
    
    private func cardFromDict(_ dict: [String: String]) -> Card? {
        guard let color = dict["color"], let value = dict["value"] else { return nil }
        return Card(color: color, value: value)
    }
    
    private func levelsFromDict(_ dict: [String: [[String: Any]]]) -> [String: Level] {
        return Dictionary(uniqueKeysWithValues: dict.map({ (playerId: String, levelGroups: [[String : Any]]) in
            let groups: [LevelGroup] = levelGroups.compactMap { group in
                guard let count = group["count"] as? Int,
                      let typeString = group["type"] as? String,
                      let type = LevelGroupType(rawValue: typeString)
                else { return nil }
                
                return LevelGroup(count: count, type: type)
            }
            
            return (playerId, Level(groups: groups))
        }))
    }
    
    private func playerFromDict(_ dict: [String: String]) -> Player? {
        guard let name = dict["name"], let id = dict["id"] else { return nil }
        return Player(name: name, id: id)
    }
    
    private func scoreFromDict(_ dict: [String: Any]) -> Score? {
        guard let level = dict["level"] as? Int,
              let playerId = dict["player_id"] as? String,
              let points = dict["points"] as? Int
        else { return nil }
        
        return Score(level: level, playerId: playerId, points: points)
    }
    
    // MARK: Notification handlers
    
    @objc private func handleNewDeviceToken(_ notification: Notification) {
        if !sentDeviceToken { sendDeviceTokenToServer() }
    }
    
    @objc private func handleSetToken(_ notification: Notification) {
        guard let token = notification.userInfo?["token"] as? String else { return }
        authToken = token
    }
}
