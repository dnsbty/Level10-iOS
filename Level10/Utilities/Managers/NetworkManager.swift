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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: NetworkManager.self))
    private let createdGameConnectMaxAttempts = 6
    private let decoder: JSONDecoder
    
    private var authToken: String?
    private var lobbyChannel: Channel?
    private var gameChannel: Channel?
    private var socket: Socket?
    private var presence: Presence?
    private var sentDeviceToken = false
    
    private init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        var configuration = Configuration()
        socket = Socket("\(configuration.environment.socketBaseUrl)/socket/websocket", paramsClosure: { [weak self] in
            guard let self = self, let authToken = self.authToken else { return [:] }
            
            let params = SocketParams(appVersion: Bundle.main.appVersion,
                                      buildNumber: Bundle.main.buildNumber,
                                      device: NotificationManager.shared.deviceToken,
                                      token: authToken)
            
            if params.device != nil {
                self.sentDeviceToken = true
            } else {
                print("No device token found")
            }
            
            return params.toDict()
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
        
        let params = AddToTableParams(cards: cards, playerId: tablePlayerId, groupPosition: groupPosition)
        
        channel.push(.addToTable, payload: params.toDict()) { (result: Result<NoReply, AddToTableError>) in
            switch result {
            case .success(_):
                NotificationCenter.default.post(name: .didAddToTable, object: nil)
            case .failure(let error):
                NotificationCenter.default.post(name: .didReceiveAddToTableError, object: nil, userInfo: ["error": error])
            }
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
            
            channel.join() { (result: Result<NoReply, ConnectError>) in
                switch result {
                case .success(_):
                    print("Lobby joined")
                case .failure(let error):
                    if error == .updateRequired {
                        channel.leave()
                        NotificationCenter.default.post(name: .versionUnsupported, object: nil)
                    }
                }
            }
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
        
        let params = CreateGameParams(displayName: name, settings: settings)
        
        channel.push(.createGame, payload: params.toDict(), with: decoder) { (result: Result<JoinCodePayload, GameCreationError>) in
            switch result {
            case .success(let payload):
                self.connectToCreatedGame(joinCode: payload.joinCode, remainingAttempts: self.createdGameConnectMaxAttempts)
            case .failure(let error):
                NotificationCenter.default.post(name: .didReceiveGameCreationError, object: nil, userInfo: ["error": error])
            }
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
        
        let params = DiscardParams(card: card, playerToSkip: playerToSkip)
        
        channel.push(.discard, payload: params.toDict(), with: decoder) { (result: Result<HandUpdatedPayload, GameCreationError>) in
            switch result {
            case .success(let payload):
                NotificationCenter.default.post(name: .handDidUpdate, object: nil, userInfo: ["hand": payload.hand])
            case .failure(let error):
                NotificationCenter.default.post(name: .didReceiveGameCreationError, object: nil, userInfo: ["error": error])
            }
        }
    }
    
    /**
     Draws a card from either the draw pile or the discard pile.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func drawCard(source: DrawSource) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        let params = DrawCardParams(source: source)
        
        channel.push(.drawCard, payload: params.toDict(), with: decoder) { (result: Result<CardPayload, CardDrawError>) in
            switch result {
            case .success(let payload):
                NotificationCenter.default.post(name: .didDrawCard, object: nil, userInfo: ["newCard": payload.card])
            case .failure(let error):
                NotificationCenter.default.post(name: .didReceiveCardDrawError, object: nil, userInfo: ["error": error])
            }
        }
    }
    
    /**
     Leaves the game once it is complete and clears all the state.
     */
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
        let params = JoinGameParams(displayName: name)
        self.connectToGame(joinCode: joinCode, params: params) { error in
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
        gameChannel?.push(.leaveGame, payload: [:])
        gameChannel?.leave()
        gameChannel = nil
        sentDeviceToken = false
        NotificationCenter.default.post(name: .didLeaveGame, object: nil)
    }
    
    /**
     Leaves the game while still in the lobby.
     */
    func leaveLobby() {
        gameChannel?.push(.leaveLobby, payload: [:])
        gameChannel?.leave()
        gameChannel = nil
        sentDeviceToken = false
        NotificationCenter.default.post(name: .didLeaveGame, object: nil)
    }
    
    /**
     Marks the player as ready to start the next round.
     */
    func markReady() {
        gameChannel?.push(.markReady, payload: [:])
    }
    
    /**
     Reconnect to a game that the player has already created or joined.
     
     - Parameter withCode: The join code for the game to which connection should be re-established.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func reconnectToGame(withCode joinCode: String) async throws {
        guard let socket = socket else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        self.connectToGame(joinCode: joinCode) { error in
            guard error == nil else {
                UserDefaults.standard.set(nil, forKey: UserDefaultsKeys.joinCodeKey)
                return
            }
            print("Reconnected to game", joinCode)
        }
    }
    
    /**
     Sends the device's token to the server to allow for push notifications to be received.
     */
    func sendDeviceTokenToServer() {
        guard let channel = gameChannel,
              let deviceToken = NotificationManager.shared.deviceToken
        else { return }
        
        let params = TokenParams(token: deviceToken)
        channel.push(.putDeviceToken, payload: params.toDict())
        sentDeviceToken = true
    }
    
    /**
     Starts a game. Expects the player sending the message to be the player who created the game.
     */
    func startGame() {
        gameChannel?.push(.startGame, payload: [:])
    }
    
    /**
     Adds cards from the player's hand to their table.
     
     - Throws: `NetworkError.socketNotConnected` if the socket wasn't properly created for some reason.
     */
    func tableCards(table: [[Card]]) async throws {
        guard let socket = socket, let channel = gameChannel else { throw NetworkError.socketNotConnected }
        if !socket.isConnected { await connectSocket() }
        
        let params = SetTableParams(table: table)
        
        channel
            .push(.tableCards, payload: params.toDict(), with: decoder) { (result: Result<NoReply, TableSetError>) in
                switch result {
                case .success(_):
                    NotificationCenter.default.post(name: .didSetTable, object: nil)
                case .failure(let error):
                    NotificationCenter.default.post(name: .didReceiveTableSetError, object: nil, userInfo: ["error": error])
                }
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
            NotificationCenter.default.post(name: .didReceiveGameCreationError, object: nil, userInfo: ["error": GameCreationError.networkError])
            return
        }
        
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
        connectToGame(joinCode: joinCode, params: JoinGameParams(displayName: nil), completionHandler: completionHandler)
    }
    
    private func connectToGame(joinCode: String, params: JoinGameParams, completionHandler: ((GameConnectError?) -> Void)?) {
        guard let socket = socket else { return }
        self.gameChannel = socket.channel("game:\(joinCode)", params: params.toDict())
        guard let gameChannel = gameChannel else { return }
        
        presence = Presence(channel: gameChannel)
        presence!.onSync {
            let connectedUsers = Set(self.presence!.state.keys)
            NotificationCenter.default.post(name: .didReceivePresenceUpdate, object: nil, userInfo: ["connectedUsers": connectedUsers])
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        gameChannel.on(.gameFinished, with: decoder) { (payload: GameFinishedPayload) in
            NotificationCenter.default.post(name: .gameDidFinish, object: nil, userInfo: ["payload": payload])
        }
        
        gameChannel.on(.gameStarted, with: decoder) { (game: Game) in
            NotificationCenter.default.post(name: .gameDidStart, object: nil, userInfo: ["game": game])
        }
        
        gameChannel.on(.handCountsUpdated, with: decoder) { (payload: HandCountUpdatePayload) in
            NotificationCenter.default.post(name: .didReceiveUpdatedHandCounts, object: nil, userInfo: ["handCounts": payload.handCounts])
        }
        
        gameChannel.on(.latestState, with: decoder) { (game: Game) in
            NotificationCenter.default.post(name: .didReceiveGameState, object: nil, userInfo: ["game": game])
        }
        
        gameChannel.on(.newDiscardTop, with: decoder) { (payload: NewDiscardTopPayload) in
            var info: [String: Any] = [:]
            if let discardTop = payload.discardTop { info["discardTop"] = discardTop }
            NotificationCenter.default.post(name: .discardTopDidChange, object: nil, userInfo: info)
        }
        
        gameChannel.on(.newTurn, with: decoder) { (payload: PlayerIdPayload) in
            NotificationCenter.default.post(name: .currentPlayerDidUpdate, object: nil, userInfo: ["player": payload.player])
        }
        
        gameChannel.on(.playerRemoved, with: decoder) { (payload: PlayerIdPayload) in
            NotificationCenter.default.post(name: .didRemovePlayer, object: nil, userInfo: ["player": payload.player])
        }
        
        gameChannel.on(.playersReady, with: decoder) { (payload: PlayerIdListPayload) in
            NotificationCenter.default.post(name: .didReceivePlayersReadyUpdate, object: nil, userInfo: ["playersReady": Set(payload.players)])
        }
        
        gameChannel.on(.playersUpdated, with: decoder) { (payload: PlayerListPayload) in
            NotificationCenter.default.post(name: .didReceiveUpdatedPlayerList, object: nil, userInfo: ["players": payload.players])
        }
        
        gameChannel.on(.roundFinished, with: decoder) { (payload: RoundFinishedPayload) in
            NotificationCenter.default.post(name: .roundDidFinish, object: nil, userInfo: ["payload": payload])
        }
        
        gameChannel.on(.roundStarted, with: decoder) { (payload: RoundStartPayload) in
            NotificationCenter.default.post(name: .roundDidStart, object: nil, userInfo: ["payload": payload])
        }
        
        gameChannel.on(.skippedPlayersUpdated, with: decoder) { (payload: SkippedPlayersPayload) in
            NotificationCenter.default.post(name: .skippedPlayersDidUpdate, object: nil, userInfo: ["skippedPlayers": payload.skippedPlayers])
        }
        
        gameChannel.on(.tableUpdated, with: decoder) { (payload: TableUpdatedPayload) in
            NotificationCenter.default.post(name: .tableDidUpdate, object: nil, userInfo: ["table": payload.table])
        }
        
        gameChannel.join(with: decoder) { [weak self] (result: Result<NoReply, GameConnectError>) in
            switch result {
            case .success(_):
                print("Connected to game")
                
                if let self = self, !self.sentDeviceToken,
                   NotificationManager.shared.deviceToken != nil {
                    self.sendDeviceTokenToServer()
                }
                
                if let completionHandler = completionHandler { completionHandler(nil) }
            case .failure(let error):
                guard let self = self else { return }
                gameChannel.leave()
                self.gameChannel = nil
                if let completionHandler = completionHandler { completionHandler(error) }
            }
        }
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
