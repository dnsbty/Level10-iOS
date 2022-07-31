//
//  Score.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation

struct Score: Codable {
    let level: Int
    let playerId: String
    let points: Int
}

extension Score: Comparable, Equatable {
    static func < (lhs: Score, rhs: Score) -> Bool {
        if lhs.level != rhs.level {
            return lhs.level > rhs.level
        } else {
            return lhs.points < rhs.points
        }
    }
    
    static func == (lhs: Score, rhs: Score) -> Bool {
        return lhs.level == rhs.level && lhs.points == rhs.points
    }
}
