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
        ZStack(alignment: .top) {
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
                            HapticManager.playLightImpact()
                            SoundManager.shared.playButtonTap()
                            
                            guard viewModel.players.count > 1 else {
                                viewModel.error = "At least 2 players are needed to play Level 10. Time to make some friends! 😘"
                                return
                            }
                            
                            NetworkManager.shared.startGame()
                        } label: {
                            L10Button(text: "Start Game", type: .primary).padding()
                        }
                    }
                }

                HStack {
                    Button {
                        HapticManager.playLightImpact()
                        SoundManager.shared.playButtonTap()
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
            
            if let startError = viewModel.error {
                ErrorBanner(message: startError, displaySeconds: 5, type: .error) {
                    withAnimation {
                        viewModel.error = nil
                    }
                }
                .zIndex(1)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.error)
            }
        }
    }
}

struct LobbyView_Previews: PreviewProvider {
    static var viewModel: GameViewModel {
        let viewModel = GameViewModel()
        viewModel.players = [
            Player(name: "Dennis", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8"),
            Player(name: "Kira", id: "64d7f3b7-390e-4948-849e-a8745174db0e"),
            Player(name: "Lily", id: "13c059c6-f4ad-4b05-87ca-2a61390f9042"),
            Player(name: "Brett", id: "eb180f94-a899-4915-b2e8-57b8ea3e6103"),
            Player(name: "Danny", id: "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c"),
            Player(name: "Megan", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4")
        ]
        viewModel.connectedPlayers = [
            "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c",
            "13c059c6-f4ad-4b05-87ca-2a61390f9042",
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "eb180f94-a899-4915-b2e8-57b8ea3e6103"
        ]
        viewModel.isCreator = true
        viewModel.joinCode = "ABCD"
        return viewModel
    }
    
    static var previews: some View {
        LobbyView()
            .environmentObject(viewModel)
    }
}
