//
//  Level.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation

struct Level: Codable {
    let groups: [LevelGroup]
    
    init(groups: [LevelGroup]) { self.groups = groups }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var levelGroups: [LevelGroup] = []
        
        while !container.isAtEnd {
            let nestedDecoder = try container.superDecoder()
            let levelGroup = try LevelGroup(from: nestedDecoder)
            levelGroups.append(levelGroup)
        }
        
        groups = levelGroups
    }
    
    func isValid(_ playerTable: [[Card]]) -> Bool {
        for i in groups.indices {
            if !groups[i].isValid(playerTable[i]) { return false }
        }
        
        return true
    }
}

struct LevelGroup: Codable {
    let count: Int
    let type: LevelGroupType
    
    func isValid(_ tableGroup: [Card]) -> Bool {
        if tableGroup.count < count { return false }
        let wildCount = countWilds(tableGroup)
        let cards = removeWilds(tableGroup)
        
        switch type {
        case .color:
            let color = cards.first?.color
            for card in cards {
                if card.color != color { return false }
            }
        case .run:
            let sortedCards = cards.sorted()
            if sortedCards.count < 2 { return true }
            let previousValue = sortedCards.first!.value
            return isValidRun(sortedCards.dropFirst(), previousValue: previousValue, unusedWilds: wildCount)
        case .set:
            let value = cards.first?.value
            for card in cards {
                if card.value != value { return false }
            }
        }
        
        return true
    }
    
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
    
    // MARK: Private functions
    
    private func countWilds(_ cards: [Card]) -> Int {
        var count = 0
        for card in cards {
            if card.value == .wild { count += 1 }
        }
        return count
    }
    
    private func isValidRun(_ cards: ArraySlice<Card>, previousValue: CardValue, unusedWilds: Int) -> Bool {
        guard let card = cards.first else { return true }
        guard let expectedValue = nextRunValue(previousValue) else { return false }
        if card.value == expectedValue {
            return isValidRun(cards.dropFirst(), previousValue: card.value, unusedWilds: unusedWilds)
        }
        if unusedWilds > 0 {
            return isValidRun(cards, previousValue: expectedValue, unusedWilds: unusedWilds - 1)
        }
        return false
    }
    
    private func nextRunValue(_ value: CardValue) -> CardValue? {
        switch value {
        case .one: return .two
        case .two: return .three
        case .three: return .four
        case .four: return .five
        case .five: return .six
        case .six: return .seven
        case .seven: return .eight
        case .eight: return .nine
        case .nine: return .ten
        case .ten: return .eleven
        case .eleven: return .twelve
        default: return nil
        }
    }
    
    private func removeWilds(_ cards: [Card]) -> [Card] {
        return cards.compactMap { card in
            return card.value == .wild ? nil : card
        }
    }
}

enum LevelGroupType: String, Codable {
    case color
    case run
    case set
}
