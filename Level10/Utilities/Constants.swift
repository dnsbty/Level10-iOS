//
//  Constants.swift
//  Level10
//
//  Created by Dennis Beatty on 7/4/22.
//

import UIKit

enum DeviceTypes {
    enum ScreenSize {
        static let width = UIScreen.main.bounds.size.width
        static let height = UIScreen.main.bounds.size.height
        static let maxLength = max(ScreenSize.width, ScreenSize.height)
        static let minLength = min(ScreenSize.width, ScreenSize.height)
    }
}

enum GameEvent: String {
    case addToTable = "add_to_table"
    case createGame = "create_game"
    case discard
    case drawCard = "draw_card"
    case gameFinished = "game_finished"
    case gameStarted = "game_started"
    case handCountsUpdated = "hand_counts_updated"
    case latestState = "latest_state"
    case leaveGame = "leave_game"
    case leaveLobby = "leave_lobby"
    case markReady = "mark_ready"
    case newDiscardTop = "new_discard_top"
    case newTurn = "new_turn"
    case playerRemoved = "player_removed"
    case playersReady = "players_ready"
    case playersUpdated = "players_updated"
    case putDeviceToken = "put_device_token"
    case roundFinished = "round_finished"
    case roundStarted = "round_started"
    case skippedPlayersUpdated = "skipped_players_updated"
    case startGame = "start_game"
    case tableCards = "table_cards"
    case tableUpdated = "table_updated"
}

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

struct UserDefaultsKeys {
    static let joinCodeKey = "joinCodeKey"
    static let lastVersionPromptedForReviewKey = "lastVersionPromptedForReview"
}
