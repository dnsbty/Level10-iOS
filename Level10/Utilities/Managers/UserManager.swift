//
//  UserManager.swift
//  Level10
//
//  Created by Dennis Beatty on 5/20/22.
//

import Foundation
import os

enum UserError: Error {
    case serverError
    case storageError
    case tooManyAttempts
}

enum UserPreference: String {
    case displayName = "userDisplayName"
    case skipNextPlayer = "skipNextPlayer"
}

final class UserManager {
    static let shared = UserManager()
    
    private(set) var id: String? = nil
    private(set) var token: String? = nil
    
    private var creatingUser = false
    private let idKey = "userId"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UserManager")
    
    private init() {
        if let token = getStoredToken() {
            print("Got token", token)
            if let id = getId() {
                self.token = token
                self.id = id
            } else {
                let _ = removeToken()
            }
        }
    }
    
    /**
     Gets the user's token or creates a new one. This function should only be used when establishing a socket connection.
     Once it has been established, the `token` and `id` class properties should be used instead.
     
     - Throws:
        - `UserError.serverError` if there is some error getting a new token from the server
        - `UserError.storageError` if the token can't be stored in the Keychain for some reason
        - `UserError.tooManyAttempts` if the request to create a new token is rate limited
     
     - Returns: A string containing the user's token
     */
    func getToken() async throws -> String {
        if let token = token { return token }
        
        try await createUser()
        return self.token!
    }
    
    /**
     Gets the user's preference from previous games they may have played as a boolean.
     */
    func preferenceBool(forKey key: UserPreference) -> Bool? {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    /**
     Gets the user's preference from previous games they may have played as a string.
     */
    func preferenceString(forKey key: UserPreference) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    /**
     Stores the user's preference to be remembered when they create or join new games in the future.
     */
    func rememberPreference(_ value: Any?, forKey key: UserPreference) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    /**
     Remove the existing token and create a new one to replace it.
     
     Emits the .didSetToken Notification when successful, with the token in the userInfo dictionary.
     */
    func refreshToken() {
        Task { [weak self] in
            guard let self = self else { return }
            let _ = removeToken()
            if let _ = try? await createUser(), let token = self.token {
                NotificationCenter.default.post(name: .didSetToken, object: nil, userInfo: ["token": token])
            }
        }
    }
    
    // MARK: Private functions
    
    private func createUser() async throws {
        // Make sure that we're only creating one user at a time to avoid race conditions
        if creatingUser { return }
        creatingUser = true
        defer { creatingUser = false }
        
        do {
            let user = try await NetworkManager.shared.createUser()
            if self.setToken(user.token) {
                self.setId(user.id)
            } else {
                throw UserError.storageError
            }
        } catch NetworkError.requestRateLimited {
            throw UserError.tooManyAttempts
        } catch {
            throw UserError.serverError
        }
    }
    
    private func getId() -> String? {
        UserDefaults.standard.string(forKey: idKey)
    }
    
    private func getStoredToken() -> String? {
        var configuration = Configuration()
        var ref: AnyObject?
        
        let getQuery = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: configuration.environment.tokenTag,
            kSecReturnData: true
        ] as CFDictionary
        
        let status = SecItemCopyMatching(getQuery, &ref)
        
        if status != errSecSuccess {
            self.logger.error("User token fetch failed: \(SecCopyErrorMessageString(status, nil) ?? "Unknown error" as CFString)")
            return nil
        }
        
        if let result = ref as? Data {
            return String(data: result, encoding: .utf8)
        }
        
        return nil
    }
    
    private func removeToken() -> Bool {
        var configuration = Configuration()
        
        let removeQuery = [
            kSecAttrApplicationTag: configuration.environment.tokenTag,
            kSecClass: kSecClassKey
        ] as CFDictionary
        
        let status = SecItemDelete(removeQuery)
        
        if status == errSecSuccess {
            self.token = nil
            return true
        } else {
            return false
        }
    }
    
    private func setId(_ id: String) {
        self.id = id
        UserDefaults.standard.set(id, forKey: idKey)
    }
    
    private func setToken(_ token: String) -> Bool {
        var configuration = Configuration()
        let tokenData = token.data(using: .utf8, allowLossyConversion: false)!
        
        let addQuery = [
            kSecValueData: tokenData,
            kSecAttrApplicationTag: configuration.environment.tokenTag,
            kSecClass: kSecClassKey
        ] as CFDictionary
        
        let status = SecItemAdd(addQuery, nil)
        
        if status != errSecSuccess {
            self.logger.error("User token write failed: \(SecCopyErrorMessageString(status, nil) ?? "Unknown error" as CFString)")
            return false
        }
        
        self.token = token
        return true
    }
}
