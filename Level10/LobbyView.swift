//
//  LobbyView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct LobbyView: View {
    @Environment(\.currentScreen) var currentScreen

    var body: some View {
        ZStack {
            Color.violet700.ignoresSafeArea()

            VStack {
                Text("Join Code")
                    .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)

                Text("QEL6")
                    .font(.system(size: 40.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Players")
                    .font(.system(size: 22.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                    .padding()

                VStack(alignment: .leading) {
                    ForEach(0..<6) { _ in
                        HStack(spacing: 18) {
                            StatusIndicator(status: .offline)

                            Text("Christopher")
                                .font(.system(size: 30.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Spacer()
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))

                Spacer()



                Button {
                    currentScreen.wrappedValue = .game
                } label: {
                    L10Button(text: "Start Game", type: .primary).padding()
                }

                HStack {
                    Button {
                        currentScreen.wrappedValue = .home
                    } label: {
                        L10Button(text: "Leave", type: .ghost)
                    }

                    Button {
                        currentScreen.wrappedValue = .lobby
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
        LobbyView().environmentObject(Navigation())
    }
}
