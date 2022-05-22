//
//  Game.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

struct Game: Codable {
    let joinCode: String
    let players: [Player]
    let settings: GameSettings
}

struct GameSettings: Codable {
    let skipNextPlayer: Bool
}

struct Player: Codable {
    let displayName: String
    let id: String
}
