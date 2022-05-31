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

struct Player: Codable, Identifiable {
    let name: String
    let id: String
}

struct Level: Codable {
    let groups: [LevelGroup]
}

struct LevelGroup: Codable {
    let count: Int
    let type: LevelGroupType
    
    func toString() -> String {
        switch type {
        case .color:
            return "\(count) of One Color"
        case .run:
            return "Run of \(count)"
        case .set:
            return "Set of \(count)"
        }
    }
}

enum LevelGroupType: String, Codable {
    case color
    case run
    case set
}

enum DrawSource: String, Codable {
    case discardPile = "discard_pile"
    case drawPile = "draw_pile"
}
