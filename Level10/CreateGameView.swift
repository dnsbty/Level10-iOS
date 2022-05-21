//
//  CreateGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct CreateGameView: View {
    @Environment(\.currentScreen) var currentScreen
    @State var displayName = UserManager.shared.preferenceString(forKey: .displayName) ?? ""
    @State var skipNextPlayer = UserManager.shared.preferenceBool(forKey: .skipNextPlayer) ?? false

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

                L10TextField(labelText: "Display Name", value: $displayName)
                    .padding()

                Spacer()

                HStack(spacing: 24.0) {
                    Toggle("Skip Next Player", isOn: $skipNextPlayer)
                        .labelsHidden()
                        .foregroundColor(.red500)
                        .tint(.red500)

                    VStack(alignment: .leading) {
                        Text("Skip Next Player")
                            .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text("When skip cards are played the next player will be skipped, rather than allowing the player who discarded the skip to choose.")
                            .font(.system(size: 18.0, design: .rounded))
                            .foregroundColor(.violet300)
                    }
                }
                .padding()

                Spacer()

                Button {
                    createGame()
                } label: {
                    L10Button(text: "Create Game", type: .primary).padding()
                }

                Button {
                    currentScreen.wrappedValue = .home
                } label: {
                    L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
                }
            }
        }
    }

    private func createGame() {
        UserManager.shared.rememberPreference(displayName, forKey: .displayName)
        UserManager.shared.rememberPreference(skipNextPlayer, forKey: .skipNextPlayer)

        // Create the game via the websocket

        currentScreen.wrappedValue = .lobby
    }
}

struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView()
    }
}
