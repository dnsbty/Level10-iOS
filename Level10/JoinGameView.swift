//
//  JoinGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct JoinGameView: View {
    @EnvironmentObject var navigation: Navigation
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
                
                
                Button {
                    navigation.currentScreen = .lobby
                } label: {
                    L10Button(text: "Join Game", type: .primary).padding()
                }
                
                Button {
                    navigation.currentScreen = .home
                } label: {
                    L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
                }
            }
        }
    }
}

struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView().environmentObject(Navigation())
    }
}
