//
//  Constants.swift
//  Level10
//
//  Created by Dennis Beatty on 7/4/22.
//

import Foundation

struct RandomEmoji {
    private static let happyEmoji = ["🎉", "😄", "😎", "🤩", "🤑", "🔥"]
    private static let sadEmoji = ["💥", "💩", "😈", "🥴", "😧", "😑", "😡", "🤬", "😵", "😩", "😢", "😭", "😒", "😔"]
    
    static func happy() -> String {
        return happyEmoji.randomElement()!
    }
    
    static func sad() -> String {
        return sadEmoji.randomElement()!
    }
}
