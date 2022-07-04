//
//  Notification+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

extension Notification.Name {
    static let connectionDidFail = Notification.Name("connectionDidFail")
    static let currentPlayerDidUpdate = Notification.Name("currentPlayerDidUpdate")
    static let didAddToTable = Notification.Name("didAddToTable")
    static let didCreateGame = Notification.Name("didCreateGame")
    static let didDrawCard = Notification.Name("didDrawCard")
    static let didEndGame = Notification.Name("didEndGame")
    static let didJoinGame = Notification.Name("didJoinGame")
    static let didLeaveGame = Notification.Name("didLeaveGame")
    static let didReceiveAddToTableError = Notification.Name("didReceiveAddToTableError")
    static let didReceiveCardDrawError = Notification.Name("didReceiveCardDrawError")
    static let didReceiveDiscardError = Notification.Name("didReceiveDiscardError")
    static let didReceiveGameCreationError = Notification.Name("didReceiveGameCreationError")
    static let didReceiveGameState = Notification.Name("didReceiveGameState")
    static let didReceivePlayersReadyUpdate = Notification.Name("didReceivePlayersReadyUpdate")
    static let didReceivePresenceUpdate = Notification.Name("didReceivePresenceUpdate")
    static let didReceiveTableSetError = Notification.Name("didReceiveTableSetError")
    static let didReceiveUpdatedHandCounts = Notification.Name("didReceiveUpdatedHandCounts")
    static let didReceiveUpdatedPlayerList = Notification.Name("didReceiveUpdatedPlayerList")
    static let didRegisterDeviceToken = Notification.Name("didRegisterDeviceToken")
    static let didSetTable = Notification.Name("didSetTable")
    static let didSetToken = Notification.Name("didSetToken")
    static let discardTopDidChange = Notification.Name("discardTopDidChange")
    static let gameDidFinish = Notification.Name("gameDidFinish")
    static let gameDidStart = Notification.Name("gameDidStart")
    static let gameJoinError = Notification.Name("gameJoinError")
    static let handDidUpdate = Notification.Name("handDidUpdate")
    static let roundDidFinish = Notification.Name("roundDidFinish")
    static let roundDidStart = Notification.Name("roundDidStart")
    static let tableDidUpdate = Notification.Name("tableDidUpdate")
}
