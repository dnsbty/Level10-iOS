//
//  Game.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

struct Game: Codable {
    var currentPlayer: String
    var discardTop: Card
    var gameOver: Bool?
    var hand: [Card]
    var handCounts: [String: Int]?
    var hasDrawn: Bool?
    var levels: [String: Level]
    var players: [Player]
    var playersReady: Set<String>?
    var remainingPlayers: Set<String>?
    var roundNumber: Int?
    var roundWinner: Player?
    var scores: [Score]?
    var settings: GameSettings
    var skippedPlayers: Set<String>?
    var table: [String: [[Card]]]?
}

struct GameSettings: Codable {
    let skipNextPlayer: Bool
    
    func toDict() -> [String: Any] {
        ["skip_next_player": skipNextPlayer]
    }
}

struct Player: Codable, Identifiable {
    let name: String
    let id: String
}

enum DrawSource: String, Codable {
    case discardPile = "discard_pile"
    case drawPile = "draw_pile"
}
