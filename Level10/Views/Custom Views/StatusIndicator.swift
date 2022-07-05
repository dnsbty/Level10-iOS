//
//  StatusIndicator.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

enum OnlineStatus {
    case online, offline
}

struct StatusIndicator: View {
    var status: OnlineStatus
    
    var body: some View {
        if (status == .online) {
            Circle()
                .foregroundColor(.green400)
                .frame(width: 12, height: 12, alignment: .leading)
        } else {
            Circle()
                .strokeBorder(lineWidth: 1.25)
                .foregroundColor(.slate400)
                .frame(width: 12, height: 12, alignment: .leading)
        }
    }
}

struct StatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            StatusIndicator(status: .online)
        }
        .previewLayout(PreviewLayout.fixed(width: 40, height: 40))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            StatusIndicator(status: .offline)
        }
        .previewLayout(PreviewLayout.fixed(width: 40, height: 40))
    }
}
