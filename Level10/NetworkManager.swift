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
    case unknownError
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NetworkManager")
    
    private var authToken: String?
    private var socket: Socket?
    
    private init() {
        var configuration = Configuration()
        socket = Socket("\(configuration.environment.socketBaseUrl)/socket/websocket", paramsClosure: { [weak self] in
            guard let self = self else { return [:] }
            return ["token": self.authToken ?? ""]
        })
        
        guard let socket = socket else { return }
        socket.onOpen { print("Socket opened") }
        socket.onClose { print("Socket closed") }
        socket.onError { (error) in print("Socket error", error) }
        socket.logger = { message in print("LOG:", message) }
    }
    
    func connectSocket() async {
        guard let socket = socket else { return }
        do {
            authToken = try await UserManager.shared.getToken()
            socket.connect()
        } catch {
            print("Error connecting to socket: ", error)
        }
    }
    
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
}
