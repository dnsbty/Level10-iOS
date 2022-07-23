//
//  Configuration.swift
//  Level10
//
//  Created by Dennis Beatty on 5/20/22.
//

import Foundation

enum DeploymentStage: String {
    case Development = "development"
    case Production = "production"

    var apiBaseUrl: String {
        switch self {
        case .Development: return "https://level10.dnsbty.com"
        case .Production: return "https://level10.games"
        }
    }

    var socketBaseUrl: String {
        switch self {
        case .Development: return "wss://level10.dnsbty.com"
        case .Production: return "wss://level10.games"
        }
    }
    
    var tokenTag: String {
        switch self {
        case .Development: return "com.dnsbty.level10.Level10.userToken"
        case .Production: return "games.level10.Level10.userToken"
        }
    }
    
    var unsupportedVersionKey: String {
        switch self {
        case .Development: return "unsupported-version-development"
        case .Production: return "unsupported-version-production"
        }
    }
    
    var userIdKey: String {
        switch self {
        case .Development: return "user-id-development"
        case .Production: return "user-id-production"
        }
    }
}

struct Configuration {
    lazy var environment: DeploymentStage = {
        if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
            if let _ = configuration.range(of: "Development") {
                return DeploymentStage.Development
            }
        }
        
        return DeploymentStage.Production
    }()
}
