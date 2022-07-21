//
//  JoinGameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct JoinGameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State var displayName = UserManager.shared.preferenceString(forKey: .displayName) ?? ""
    @State var joinCode = ""

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

                Spacer()

                L10TextField(labelText: "Display Name", value: $displayName)
                    .padding()

                L10TextField(labelText: "Join Code", value: $joinCode)
                    .keyboardType(.alphabet)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .padding()

                Spacer()

                if viewModel.waitingOnAction {
                    L10Button(text: "Joining Game...", type: .primary, disabled: true).padding()
                } else {
                    Button {
                        SoundManager.shared.playButtonTap()
                        joinGame()
                    } label: {
                        L10Button(text: "Join Game", type: .primary).padding()
                    }
                }

                Button {
                    HapticManager.playLightImpact()
                    SoundManager.shared.playButtonTap()
                    viewModel.currentScreen = .home
                    viewModel.joinCode = nil
                    viewModel.waitingOnAction = false
                    viewModel.error = nil
                } label: {
                    L10Button(text: "Nevermind", type: .ghost).padding(.horizontal)
                }
            }
            
            if let joinError = viewModel.error {
                ErrorBanner(message: joinError, displaySeconds: 5, type: .error) {
                    withAnimation {
                        viewModel.error = nil
                    }
                }
                .zIndex(1)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.error)
            }
        }
        .onAppear {
            if let joinCode = viewModel.joinCode {
                self.joinCode = joinCode
            }
        }
    }
    
    private func joinGame() {
        guard !viewModel.waitingOnAction else { return }
        guard !displayName.isEmpty else {
            HapticManager.playError()
            viewModel.error = "Please enter a name to be displayed to the other players. It doesn't even have to be your real one 😂"
            return
        }
        guard !joinCode.isEmpty else {
            HapticManager.playError()
            viewModel.error = "How do you expect to join a game if you don't know which one you want to join? 🤨"
            return
        }
        
        viewModel.waitingOnAction = true
        UserManager.shared.rememberPreference(displayName, forKey: .displayName)
        
        Task {
            do {
                try await NetworkManager.shared.joinGame(withCode: joinCode, displayName: displayName)
            } catch {
                HapticManager.playError()
                viewModel.waitingOnAction = false
                withAnimation { viewModel.error = "The socket isn't connected 🤓" }
            }
        }
    }
}

struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView()
            .environmentObject(GameViewModel())
    }
}
