//
//  Card.swift
//  Level10
//
//  Created by Dennis Beatty on 5/29/22.
//

import Foundation

struct Card {
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
}

enum CardColor: String {
    case red, yellow, green, blue, black
}

enum CardValue: String {
    case one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, skip, wild
}
