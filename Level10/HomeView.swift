//
//  HomeView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var navigation: Navigation
    
    var body: some View {
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Text("Level 10")
                    .font(.system(size: 53.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Spacer()
                
                Spacer()
                
                Button {
                    navigation.currentScreen = .create
                } label: {
                    L10Button(text: "Create Game", type: .secondary).padding(.horizontal)
                }
                
                Button {
                    navigation.currentScreen = .join
                } label: {
                    L10Button(text: "Join Game", type: .primary).padding()
                }
                
                Spacer()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(Navigation())
    }
}
