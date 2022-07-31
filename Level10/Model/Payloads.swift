//
//  Payloads.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation

// MARK: Incoming Payloads

struct CardPayload: Decodable {
    let card: Card
}

struct ConnectErrorPayload: Decodable {
    let reason: ConnectError
}

struct ErrorPayload<T: Decodable & Error>: Decodable, Error {
    let error: T
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case error, reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let key = container.allKeys.filter({ CodingKeys.allCases.contains($0) }).first {
            error = try container.decode(T.self, forKey: key)
        } else {
            let context = DecodingError.Context(codingPath: [CodingKeys.error],
                                                debugDescription: "Neither an error nor a reason key was found in the given error payload.")
            throw DecodingError.keyNotFound(CodingKeys.error, context)
        }
    }
}

struct GameFinishedPayload: Codable {
    let roundWinner: Player
    let scores: [Score]
}

struct HandCountUpdatePayload: Codable {
    let handCounts: [String: Int]
}

struct HandUpdatedPayload: Codable {
    let hand: [Card]
}

struct JoinCodePayload: Codable {
    let joinCode: String
}

struct NewDiscardTopPayload: Codable {
    let discardTop: Card?
}

struct NoReply: Decodable {}

struct PlayerIdListPayload: Codable {
    let players: [String]
}

struct PlayerIdPayload: Codable {
    let player: String
}

struct PlayerListPayload: Codable {
    let players: [Player]
}

struct RoundFinishedPayload: Codable {
    let winner: Player
    let scores: [Score]
}

struct RoundStartPayload: Codable {
    let currentPlayer: String
    let discardTop: Card
    let hand: [Card]
    let handCounts: [String: Int]
    let levels: [String: Level]
    let remainingPlayers: Set<String>
    let roundNumber: Int
    let settings: GameSettings
}

struct SkippedPlayersPayload: Codable {
    let skippedPlayers: Set<String>
}

struct TableUpdatedPayload: Codable {
    let table: [String: [[Card]]]
}

// MARK: Outgoing Payloads

struct AddToTableParams {
    let cards: [Card]
    let playerId: String
    let groupPosition: Int
    
    func toDict() -> [String: Any] {
        let cardDicts = cards.map { $0.forJson() }
        return ["cards": cardDicts, "player_id": playerId, "position": groupPosition]
    }
}

struct CreateGameParams {
    let displayName: String
    let settings: GameSettings
    
    func toDict() -> [String: Any] {
        ["display_name": displayName, "settings": settings.toDict()]
    }
}

struct DiscardParams {
    let card: Card
    let playerToSkip: String?
    
    func toDict() -> [String: Any] {
        var params: [String: Any] = ["card": card.forJson()]
        if let playerToSkip = playerToSkip { params["player_to_skip"] = playerToSkip }
        return params
    }
}

struct DrawCardParams {
    let source: DrawSource
    
    func toDict() -> [String: Any] {
        ["source": source.rawValue]
    }
}

struct JoinGameParams {
    let displayName: String?
    
    func toDict() -> [String: Any] {
        guard let displayName = displayName else { return [:] }
        return ["display_name": displayName]
    }
}

struct SetTableParams {
    let table: [[Card]]
    
    func toDict() -> [String: Any] {
        let tableGroups = table.map { group in
            group.compactMap { $0.forJson() }
        }
        
        return ["table": tableGroups]
    }
}

struct SocketParams {
    let appVersion: String
    let buildNumber: String
    let device: String?
    let token: String
    
    func toDict() -> [String: Any] {
        var dict = [
            "app_version": appVersion,
            "build_number": buildNumber,
            "token": token
        ]
        
        if device != nil { dict["device"] = device }
        
        return dict
    }
}

struct TokenParams {
    let token: String
    
    func toDict() -> [String: Any] {
        ["token": token]
    }
}
