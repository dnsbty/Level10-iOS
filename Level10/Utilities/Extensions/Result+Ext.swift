//
//  Result+Ext.swift
//  Level10
//
//  Created by Dennis Beatty on 7/30/22.
//

import Foundation

extension Result where Success == Void {
    public static func success() -> Self { .success(()) }
}
