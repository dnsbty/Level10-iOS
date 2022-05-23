//
//  Notification+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 5/22/22.
//

import Foundation

extension Notification.Name {
    static let didCreateGame = Notification.Name("didCreateGame")
    static let didReceiveGameCreationError = Notification.Name("didReceiveGameCreationError")
    static let didReceiveUpdatedPlayerList = Notification.Name("didReceiveUpdatedPlayerList")
}
