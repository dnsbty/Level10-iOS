//
//  JoinGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct JoinGameView: View {
    @State var displayName = ""
    @State var joinCode = ""
    
    var body: some View {
        ZStack {
            Color.violet700.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Level 10")
                    .font(.system(size: 53.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Spacer()
                
                Spacer()
                
                L10TextField(labelText: "Display Name", value: $displayName)
                    .padding()
                
                L10TextField(labelText: "Join Code", value: $joinCode)
                    .padding()
                
                Spacer()
                
                L10Button(text: "Join Game", type: .primary).padding()
                L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
            }
        }
    }
}

struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView()
    }
}
