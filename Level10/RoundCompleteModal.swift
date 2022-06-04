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
    var winner: Player
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .cornerRadius(40)
                .foregroundColor(.violet700)
                .frame(height: 260)
            
            VStack(spacing: 32) {
                Text("Round Complete \(completeEmoji(completedLevel))")
                    .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 32)
                
                Text(roundWinnerText(winner))
                    .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                
                Button {
                    print("Go to score screen")
                } label: {
                    L10Button(text: "Check the Scores", type: .primary).padding(.horizontal)
                }
            }
        }
    }
    
    private func completeEmoji(_ completedLevel: Bool) -> String {
        let happyEmoji = ["🎉", "😄", "😎", "🤩", "🤑", "🔥"]
        let sadEmoji = ["💥", "💩", "😈", "🥴", "😧", "😑", "😡", "🤬", "😵", "😩", "😢", "😭", "😒", "😔"]
        
        if completedLevel {
            return happyEmoji.randomElement()!
        } else {
            return sadEmoji.randomElement()!
        }
    }
    
    private func roundWinnerText(_ winner: Player) -> String {
        if winner.id == UserManager.shared.id { return "You won the round!" }
        return "\(winner.name) won the round."
    }
}

struct RoundCompleteModal_Previews: PreviewProvider {
    static var previews: some View {
        RoundCompleteModal(currentScreen: .constant(.game), completedLevel: true, winner: Player(name: "Dennis", id: "1234"))
    }
}
