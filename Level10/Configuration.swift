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
        case .Development: return "http://localhost:4000"
        case .Production: return "https://level10.games"
        }
    }

    var socketBaseUrl: String {
        switch self {
        case .Development: return "ws://localhost:4000"
        case .Production: return "wss://level10.games"
        }
    }
}

struct Configuration {
    lazy var environment: DeploymentStage = {
        if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
            print("Got configuration string: '\(configuration)'")
            if let _ = configuration.range(of: "Development") {
                print("Setting environment to DEVELOPMENT")
                return DeploymentStage.Development
            }
        }
        
        print("Setting environment to PRODUCTION")
        return DeploymentStage.Production
    }()
}
