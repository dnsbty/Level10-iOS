//
//  Notification+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

extension Notification.Name {
    static let currentPlayerDidUpdate = Notification.Name("currentPlayerDidUpdate")
    static let didAddToTable = Notification.Name("didAddToTable")
    static let didCreateGame = Notification.Name("didCreateGame")
    static let didDrawCard = Notification.Name("didDrawCard")
    static let didJoinGame = Notification.Name("didJoinGame")
    static let didLeaveGame = Notification.Name("didLeaveGame")
    static let didReceiveAddToTableError = Notification.Name("didReceiveAddToTableError")
    static let didReceiveCardDrawError = Notification.Name("didReceiveCardDrawError")
    static let didReceiveDiscardError = Notification.Name("didReceiveDiscardError")
    static let didReceiveGameCreationError = Notification.Name("didReceiveGameCreationError")
    static let didReceiveGameState = Notification.Name("didReceiveGameState")
    static let didReceivePresenceUpdate = Notification.Name("didReceivePresenceUpdate")
    static let didReceiveTableSetError = Notification.Name("didReceiveTableSetError")
    static let didReceiveUpdatedHandCounts = Notification.Name("didReceiveUpdatedHandCounts")
    static let didReceiveUpdatedPlayerList = Notification.Name("didReceiveUpdatedPlayerList")
    static let didSetTable = Notification.Name("didSetTable")
    static let discardTopDidChange = Notification.Name("discardTopDidChange")
    static let gameDidStart = Notification.Name("gameDidStart")
    static let handDidUpdate = Notification.Name("handDidUpdate")
    static let tableDidUpdate = Notification.Name("tableDidUpdate")
}
