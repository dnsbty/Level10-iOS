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
    case notFound
    case requestRateLimited
    case requestForbidden
    case requestUnauthorized
    case socketDoesNotExist
    case unknownError
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NetworkManager")
    
    private var authToken: String?
    private var lobbyChannel: Channel?
    private var gameChannel: Channel?
    private var socket: Socket?
    private var presence: Presence?
    
    private init() {
        var configuration = Configuration()
        socket = Socket("\(configuration.environment.socketBaseUrl)/socket/websocket", paramsClosure: { [weak self] in
            guard let self = self else { return [:] }
            return ["token": self.authToken ?? ""]
        })
        
        guard let socket = socket else { return }
        lobbyChannel = socket.channel("game:lobby")
        socket.onOpen { print("Socket opened") }
        socket.onClose { print("Socket closed") }
        socket.onError { (error) in print("Socket error", error) }
//        socket.logger = { message in print("LOG:", message) }
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
     
     - Throws: `NetworkError.socketDoesNotExist` if the socket wasn't properly created for some reason.
     */
    func createGame(withDisplayName name: String, settings: GameSettings) async throws {
        guard let socket = socket, let channel = lobbyChannel else { throw NetworkError.socketDoesNotExist }
        if !socket.isConnected { await connectSocket() }
        let params: [String: Any] = ["displayName": name, "skipNextPlayer": settings.skipNextPlayer]
        
        channel
            .push("createGame", payload: params)
            .receive("ok") { response in
                guard let joinCode = response.payload["joinCode"] as? String else { return }
                self.connectToGame(joinCode: joinCode)
                NotificationCenter.default.post(name: .didCreateGame, object: nil, userInfo: ["joinCode": joinCode])
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
    
    // MARK: Private functions
    
    private func connectToGame(joinCode: String) {
        guard let socket = socket else { return }
        gameChannel = socket.channel("game:\(joinCode)")
        guard let gameChannel = gameChannel else { return }
        
        presence = Presence(channel: gameChannel)
        presence!.onSync {
            let connectedUsers = Set(self.presence!.state.keys)
            NotificationCenter.default.post(name: .didReceivePresenceUpdate, object: nil, userInfo: ["connectedUsers": connectedUsers])
        }
        
        gameChannel.on("players_updated") { message in
            guard let playerDicts = message.payload["players"] as? [[String: String]] else { return }
            let players: [Player] = playerDicts.compactMap { dict in
                guard let name = dict["name"], let id = dict["id"] else { return nil }
                return Player(name: name, id: id)
            }
            NotificationCenter.default.post(name: .didReceiveUpdatedPlayerList, object: nil, userInfo: ["players": players])
        }
        
        gameChannel
            .join()
            .receive("ok") { message in print("Connected to game", message.payload)}
            .receive("error") { message in print("Failed to connect to game", message.payload)}
    }
}
