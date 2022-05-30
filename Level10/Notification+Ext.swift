//
//  Notification+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

extension Notification.Name {
    static let didCreateGame = Notification.Name("didCreateGame")
    static let didJoinGame = Notification.Name("didJoinGame")
    static let didLeaveGame = Notification.Name("didLeaveGame")
    static let didReceiveGameCreationError = Notification.Name("didReceiveGameCreationError")
    static let didReceiveGameState = Notification.Name("didReceiveGameState")
    static let didReceivePresenceUpdate = Notification.Name("didReceivePresenceUpdate")
    static let didReceiveUpdatedPlayerList = Notification.Name("didReceiveUpdatedPlayerList")
    static let gameDidStart = Notification.Name("gameDidStart")
}
