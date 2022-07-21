//
//  RoundCompleteModal.swift
//  Level10
//
//  Created by Dennis Beatty on 6/4/22.
//

import SwiftUI

struct RoundCompleteModal: View {
    @Binding var currentScreen: Screen
    var completedLevel: Bool
    var gameOver: Bool
    var winner: Player
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.violet700.frame(height: 50)
            
            VStack(spacing: 32) {
                Text(titleText())
                    .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 32)

                Text(roundWinnerText(winner))
                    .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)

                Button {
                    HapticManager.playLightImpact()
                    SoundManager.shared.playButtonTap()
                    currentScreen = .scoring
                } label: {
                    L10Button(text: buttonText(), type: .primary).padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
            .background(Color.violet700)
            .cornerRadius(40)
        }
    }
    
    private func buttonText() -> String {
        if gameOver {
            return "See the final scores"
        } else {
            return "Check the scores"
        }
    }
    
    private func completeEmoji(_ completedLevel: Bool) -> String {
        if completedLevel {
            return RandomEmoji.happy()
        } else {
            return RandomEmoji.sad()
        }
    }
    
    private func roundWinnerText(_ winner: Player) -> String {
        if winner.id == UserManager.shared.id { return "You won the round!" }
        return "\(winner.name) won the round."
    }
    
    private func titleText() -> String {
        if gameOver {
            return "Game over \(completeEmoji(completedLevel))"
        } else {
            return "Round Complete \(completeEmoji(completedLevel))"
        }
    }
}

struct RoundCompleteModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color.white
            
            RoundCompleteModal(currentScreen: .constant(.game), completedLevel: true, gameOver: true, winner: Player(name: "Dennis", id: "1234"))
        }
        .ignoresSafeArea()
    }
}
