//
//  Card.swift
//  Level10
//
//  Created by Dennis Beatty on 5/29/22.
//

import Foundation

struct Card: Codable {
    let color: CardColor
    let value: CardValue
    
    init(color: CardColor, value: CardValue) {
        self.color = color
        self.value = value
    }
    
    init?(color colorString: String, value valueString: String) {
        guard let color = CardColor(rawValue: colorString),
              let value = CardValue(rawValue: valueString)
        else { return nil }
        
        self.color = color
        self.value = value
    }
    
    func forJson() -> [String: String] {
        return ["color": color.rawValue, "value": value.rawValue]
    }
}

extension Card: Comparable, Equatable {
    static func < (lhs: Card, rhs: Card) -> Bool {
        if lhs.value != rhs.value {
            return lhs.value.sortValue < rhs.value.sortValue
        } else {
            return lhs.color.sortValue < rhs.color.sortValue
        }
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.color == rhs.color && lhs.value == rhs.value
    }
}

enum CardColor: String, Codable {
    case red, yellow, green, blue, black
    
    var sortValue: Int {
        switch self {
        case .red: return 1
        case .yellow: return 2
        case .green: return 3
        case .blue: return 4
        case .black: return 0
        }
    }
}

enum CardValue: String, Codable {
    case one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, skip, wild
    
    var sortValue: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .eleven: return 11
        case .twelve: return 12
        case .skip: return 13
        case .wild: return 0
        }
    }
}
