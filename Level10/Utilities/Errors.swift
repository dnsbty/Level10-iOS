//
//  Errors.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation

protocol DecodableError: Decodable, Error {
    func fromReason(_ reason: String)
}

enum AddToTableError: Decodable, Error {
    case invalidGroup
    case levelIncomplete
    case needsToDraw
    case notYourTurn
    case unrecognized(String)
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "invalid_group": self = .invalidGroup
        case "level_incomplete": self = .levelIncomplete
        case "needs_to_draw": self = .needsToDraw
        case "not_your_turn": self = .notYourTurn
        default: self = .unrecognized(reason)
        }
    }
}

enum CardDrawError: Decodable, Error {
    case alreadyDrawn
    case emptyDiscardPile
    case notYourTurn
    case skip
    case unrecognized(String)
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "already_drawn": self = .alreadyDrawn
        case "empty_discard_pile": self = .emptyDiscardPile
        case "skip": self = .skip
        case "not_your_turn": self = .notYourTurn
        default: self = .unrecognized(reason)
        }
    }
}

enum ConnectError: Decodable, Error, Equatable {
    case updateRequired
    case unrecognized(String)
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "update_required": self = .updateRequired
        default: self = .unrecognized(reason)
        }
    }
}

enum DiscardError: Decodable, Error {
    case alreadySkipped
    case chooseSkipTarget
    case needToDraw
    case noCard
    case notYourTurn
    case unrecognized(String)
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "no_card": self = .noCard
        case "already_skipped": self = .alreadySkipped
        case "choose_skip_target": self = .chooseSkipTarget
        case "not_your_turn": self = .notYourTurn
        case "need_to_draw": self = .needToDraw
        default: self = .unrecognized(reason)
        }
    }
}

enum GameConnectError: Decodable, Error {
    case alreadyStarted
    case full
    case notFound
    case unknownError(String)
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "already_started": self = .alreadyStarted
        case "full": self = .full
        case "not_found": self = .notFound
        default: self = .unknownError(reason)
        }
    }
}

enum GameCreationError: Decodable, Error {
    case networkError
    case serverError
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "socket error": self = .networkError
        default: self = .serverError
        }
    }
}

enum TableSetError: Decodable, Error {
    case invalidLevel
    case badRequest
    
    init(from decoder: Decoder) throws {
        let reason = try decoder.singleValueContainer().decode(String.self)
        
        switch reason {
        case "invalid_level": self = .invalidLevel
        default: self = .badRequest
        }
    }
}

