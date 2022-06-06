//
//  ScoreView.swift
//  Level10
//
//  Created by Dennis Beatty on 6/5/22.
//

import SwiftUI

struct ScoreView: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.violet700.ignoresSafeArea()
            
            VStack {
                Text("Scores after")
                    .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                    .padding(.top, 48)

                Text("Round \(viewModel.roundNumber)")
                    .font(.system(size: 40.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                VStack {
                    ForEach(viewModel.scores.indices, id: \.self) { scoreIndex in
                        let score = viewModel.scores[scoreIndex]
                        let player = viewModel.player(id: score.playerId)
                        
                        HStack(spacing: 18) {
                            Text("\(scoreIndex + 1).")
                                .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Text(player?.name ?? "")
                                .font(.system(size: 30.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Spacer()
                            
                            Text("\(score.points) (\(score.level))")
                                .font(.system(size: 30.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            StatusIndicator(status: viewModel.isConnected(playerId: score.playerId) ? .online : .offline)
                        }
                    }
                }
                .padding(EdgeInsets(top: 48, leading: 24, bottom: 0, trailing: 24))
                
                Spacer()
                
                Button {
                    // Mark player as ready
                } label: {
                    L10Button(text: "Next Round", type: .primary).padding(.horizontal)
                }
                
                Button {
                    NetworkManager.shared.leaveGame()
                } label: {
                    L10Button(text: "Leave Game", type: .ghost)
                }
            }
        }
    }
}

struct ScoreView_Previews: PreviewProvider {
    static var viewModel: GameViewModel {
        let viewModel = GameViewModel()
        
        viewModel.connectedPlayers = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "af225f65-7e29-4f08-b1e2-ac67abec6ab0",
            "20fc38f2-8657-47ca-8b64-72e3cc021d77",
            "211a7eda-a033-46f7-9c9a-b98041380cd1"
        ]
        
        viewModel.players = [
            Player(name: "Dennis", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8"),
            Player(name: "Kira", id: "af225f65-7e29-4f08-b1e2-ac67abec6ab0"),
            Player(name: "Lily Jo", id: "20fc38f2-8657-47ca-8b64-72e3cc021d77"),
            Player(name: "Brett", id: "679fbdde-eafa-46de-bc40-40165f68b218"),
            Player(name: "Cari", id: "211a7eda-a033-46f7-9c9a-b98041380cd1"),
            Player(name: "John", id: "cc7a02b6-4cce-4436-bf24-c7523eb7172f")
        ]
        
        viewModel.scores = [
            Score(level: 4, playerId: "b95e86d7-82d5-4444-9322-2a7405f64fb8", points: 20),
            Score(level: 4, playerId: "af225f65-7e29-4f08-b1e2-ac67abec6ab0", points: 45),
            Score(level: 3, playerId: "20fc38f2-8657-47ca-8b64-72e3cc021d77", points: 120),
            Score(level: 3, playerId: "679fbdde-eafa-46de-bc40-40165f68b218", points: 165),
            Score(level: 2, playerId: "211a7eda-a033-46f7-9c9a-b98041380cd1", points: 240),
            Score(level: 2, playerId: "cc7a02b6-4cce-4436-bf24-c7523eb7172f", points: 285)
        ]
        
        return viewModel
    }
    
    static var previews: some View {
        ScoreView()
            .environmentObject(viewModel)
    }
}
