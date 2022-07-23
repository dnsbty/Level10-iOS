//
//  UnsupportedVersionModal.swift
//  Level10
//
//  Created by Dennis Beatty on 7/22/22.
//

import SwiftUI

struct UnsupportedVersionModal: View {
    var body: some View {
        VStack {
            Text("Update required 👮‍♂️")
                .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)
            
            Text("This version of Level 10 is no longer supported. Please download the latest update from the App Store to continue playing.")
                .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                .foregroundColor(.violet200)
                .padding()
            
            Button {
                if let url = URL(string: "https://itunes.apple.com/in/app/level-10-phase-card-game/id1628395815?mt=8") {
                    HapticManager.playLightImpact()
                    SoundManager.shared.playButtonTap()
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } label: {
                L10Button(text: "Go to the App Store", type: .primary).padding()
            }
        }
        .padding()
        .background(Color.violet700, in: RoundedRectangle(cornerRadius: 40))
        .padding()
        .offset(y: -80)
    }
}

struct OldBuildModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            HomeView()
            
            Color(uiColor: .systemBackground)
                .opacity(0.25)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            UnsupportedVersionModal()
        }
    }
}
