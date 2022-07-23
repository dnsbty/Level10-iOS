//
//  Bundle+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 7/22/22.
//

import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}
