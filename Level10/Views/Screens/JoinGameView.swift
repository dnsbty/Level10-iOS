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
                        joinGame()
                    } label: {
                        L10Button(text: "Join Game", type: .primary).padding()
                    }
                }

                Button {
                    HapticManager.playLightImpact()
                    viewModel.currentScreen = .home
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
        viewModel.waitingOnAction = true
        UserManager.shared.rememberPreference(displayName, forKey: .displayName)
        
        Task {
            do {
                try await NetworkManager.shared.joinGame(withCode: joinCode, displayName: displayName)
            } catch {
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
