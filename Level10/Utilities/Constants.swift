//
//  Constants.swift
//  Level10
//
//  Created by Dennis Beatty on 7/4/22.
//

import UIKit

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

enum DeviceTypes {
    enum ScreenSize {
        static let width = UIScreen.main.bounds.size.width
        static let height = UIScreen.main.bounds.size.height
        static let maxLength = max(ScreenSize.width, ScreenSize.height)
        static let minLength = min(ScreenSize.width, ScreenSize.height)
    }
}

struct UserDefaultsKeys {
    static let lastVersionPromptedForReviewKey = "lastVersionPromptedForReview"
}
