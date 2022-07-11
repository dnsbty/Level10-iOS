//
//  LobbyView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct LobbyView: View {
    @Environment(\.currentScreen) var currentScreen
    @EnvironmentObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.violet700.ignoresSafeArea()

            VStack {
                Text("Join Code")
                    .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)

                Text(viewModel.joinCode ?? "")
                    .font(.system(size: 40.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Players")
                    .font(.system(size: 22.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                    .padding()

                VStack(alignment: .leading) {
                    ForEach(viewModel.players) { player in
                        HStack(spacing: 18) {
                            StatusIndicator(status: viewModel.isConnected(playerId: player.id) ? .online : .offline)

                            Text(player.name)
                                .font(.system(size: 30.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Spacer()
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))

                Spacer()

                if viewModel.isCreator {
                    if viewModel.waitingOnAction {
                        L10Button(text: "Starting Game...", type: .primary, disabled: true).padding()
                    } else {
                        Button {
                            NetworkManager.shared.startGame()
                        } label: {
                            L10Button(text: "Start Game", type: .primary).padding()
                        }
                    }
                }

                HStack {
                    Button {
                        NetworkManager.shared.leaveLobby()
                    } label: {
                        L10Button(text: "Leave", type: .ghost)
                    }

                    Button {
                        let url = URL(string: viewModel.inviteUrl)
                        let activityController = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        windowScene?.windows.first?.rootViewController?.present(activityController, animated: true, completion: nil)
                    } label: {
                        L10Button(text: "Invite", type: .ghost)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView()
    }
}
