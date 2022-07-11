//
//  CreateGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct CreateGameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State var displayName = UserManager.shared.preferenceString(forKey: .displayName) ?? ""
    @State var skipNextPlayer = UserManager.shared.preferenceBool(forKey: .skipNextPlayer) ?? false

    var body: some View {
        ZStack(alignment: .top) {
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
                    HapticManager.playLightImpact()
                    viewModel.currentScreen = .home
                } label: {
                    L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
                }
            }
            
            if let creationError = viewModel.error {
                ErrorBanner(message: creationError, displaySeconds: 5, type: .error) {
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

    private func createGame() {
        UserManager.shared.rememberPreference(displayName, forKey: .displayName)
        UserManager.shared.rememberPreference(skipNextPlayer, forKey: .skipNextPlayer)

        Task {
            do {
                try await NetworkManager.shared.createGame(withDisplayName: displayName,
                                                   settings: GameSettings(skipNextPlayer: skipNextPlayer))
            } catch NetworkError.socketNotConnected {
                viewModel.error = "The socket isn't connected 🤓"
            } catch NetworkError.channelNotJoined {
                viewModel.error = "The socket isn't configured properly 🤓"
            }
        }
    }
}

struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView()
            .environmentObject(GameViewModel())
    }
}
