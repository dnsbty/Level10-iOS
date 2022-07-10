//
//  LeaveConfirmModal.swift
//  Level10
//
//  Created by Dennis Beatty on 7/10/22.
//

import SwiftUI

struct LeaveConfirmModal: View {
    @Binding var showModal: Bool
    var midRound = false
    
    var explanationText: String {
        if midRound {
            return "Are you sure you want to leave right now? You'll make the game unplayable for everyone..."
        } else {
            return "Are you sure you want to leave right now? You won't be able to come back later..."
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                Text("Giving up? 😳")
                    .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 32)

                Text(explanationText)
                    .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                    .padding()

                Button {
                    HapticManager.playLightImpact()
                    if midRound {
                        NetworkManager.shared.leaveLobby()
                    } else {
                        NetworkManager.shared.leaveGame()
                    }
                } label: {
                    L10Button(text: "Leave game", type: .primary).padding(.horizontal)
                }
                
                Button {
                    withAnimation {
                        showModal = false
                    }
                } label: {
                    L10Button(text: "Stick around", type: .ghost)
                }
            }
            .padding(.bottom)
            .background(Color.violet700)
            .cornerRadius(40)
        }
    }
}

struct LeaveConfirmModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color.white
            
            LeaveConfirmModal(showModal: .constant(true))
        }
        .ignoresSafeArea()
    }
}
