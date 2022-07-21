//
//  SkipSelectModal.swift
//  Level10
//
//  Created by Dennis Beatty on 7/4/22.
//

import SwiftUI

struct SkipSelectModal: View {
    @Binding var displayModal: Bool
    var players: [Player]
    var skippedPlayers: Set<String>
    var completionHandler: ((String) -> ())
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.violet700.frame(height: 50)
            
            VStack {
                Text("Who would you like to skip?")
                    .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 24)
                
                ForEach(players) { player in
                    let alreadySkipped = skippedPlayers.contains(player.id)
                    
                    if player.id != UserManager.shared.id {
                        Button {
                            withAnimation { displayModal = false }
                            HapticManager.playMediumImpact()
                            SoundManager.shared.playButtonTap()
                            completionHandler(player.id)
                        } label: {
                            L10Button(text: player.name, type: .secondary, disabled: alreadySkipped)
                                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        }
                        .disabled(alreadySkipped)
                    }
                }
                
                Button {
                    HapticManager.playLightImpact()
                    SoundManager.shared.playButtonTap()
                    withAnimation { displayModal = false }
                } label: {
                    L10Button(text: "Discard something else", type: .ghost)
                }
            }
            .padding(.bottom)
            .background(Color.violet700)
            .cornerRadius(40)
        }
    }
}

struct SkipSelectModal_Previews: PreviewProvider {
    static let players = [
        Player(name: "Dennis", id: "1234"),
        Player(name: "Kira", id: "5678"),
        Player(name: "Brett", id: "42069")
    ]
    
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color.white
            
            SkipSelectModal(displayModal: .constant(true), players: players, skippedPlayers: ["5678"]) { playerId in
                print("Player \(playerId) was selected")
            }
        }
        .ignoresSafeArea()
    }
}
