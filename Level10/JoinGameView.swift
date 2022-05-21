//
//  JoinGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct JoinGameView: View {
    @Environment(\.currentScreen) var currentScreen
    @State var displayName = UserManager.shared.preferenceString(forKey: .displayName) ?? ""
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
                    joinGame()
                } label: {
                    L10Button(text: "Join Game", type: .primary).padding()
                }

                Button {
                    currentScreen.wrappedValue = .home
                } label: {
                    L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
                }
            }
        }
    }
    
    private func joinGame() {
        UserManager.shared.rememberPreference(displayName, forKey: .displayName)
        
        // Join the game via the websocket
        
        currentScreen.wrappedValue = .lobby
    }
}

struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView()
    }
}
