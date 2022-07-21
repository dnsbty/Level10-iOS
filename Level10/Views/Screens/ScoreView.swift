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
        ZStack(alignment: .bottom) {
            Color.violet700.ignoresSafeArea()
            
            VStack {
                Text(headerLabelText())
                    .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                    .foregroundColor(.violet200)
                    .padding(.top, 48)

                Text(headerText())
                    .font(.system(size: 40.0, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                VStack {
                    ForEach(viewModel.scores.indices, id: \.self) { scoreIndex in
                        let score = viewModel.scores[scoreIndex]
                        let player = viewModel.player(id: score.playerId)
                        
                        HStack(spacing: 8) {
                            Text(viewModel.remainingPlayers.contains(score.playerId) ? "\(scoreIndex + 1)." : "💀")
                                .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            Text(player?.name ?? "")
                                .font(.system(size: 28.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .strikethrough(!viewModel.remainingPlayers.contains(score.playerId))

                            Spacer()
                            
                            Text("\(score.points)")
                                .font(.system(size: 28.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(levelText(score.level))
                                .font(.system(size: 28.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 56)
                            
                            if viewModel.isReady(playerId: score.playerId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .frame(width: 12, height: 12, alignment: .leading)
                            } else {
                                StatusIndicator(status: viewModel.isConnected(playerId: score.playerId) ? .online : .offline)
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: 48, leading: 24, bottom: 48, trailing: 24))
                
                Spacer()
                
                if viewModel.gameOver {
                    Button {
                        HapticManager.playLightImpact()
                        SoundManager.shared.playButtonTap()
                        NetworkManager.shared.markReady()
                    } label: {
                        L10Button(text: "End Game", type: .primary).padding()
                    }
                } else {
                    if viewModel.isReady(playerId: UserManager.shared.id ?? "b95e86d7-82d5-4444-9322-2a7405f64fb8") {
                        Text("Waiting for others...")
                            .font(.system(size: 24.0, weight: .semibold, design: .rounded))
                            .foregroundColor(.violet200)
                            .padding(.bottom)
                    } else {
                        Button {
                            HapticManager.playLightImpact()
                            SoundManager.shared.playButtonTap()
                            NetworkManager.shared.markReady()
                        } label: {
                            L10Button(text: "Next Round", type: .primary).padding(.horizontal)
                        }
                    }
                    
                    Button {
                        HapticManager.playLightImpact()
                        SoundManager.shared.playButtonTap()
                        withAnimation {
                            viewModel.showLeaveModal = true
                        }
                    } label: {
                        L10Button(text: "Leave Game", type: .ghost)
                    }.padding(.bottom)
                }
            }
            
            ZStack(alignment: .bottom) {
                if viewModel.showLeaveModal {
                    Color(uiColor: .systemBackground).opacity(0.8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showLeaveModal)
                        .onTapGesture {
                            withAnimation { viewModel.showLeaveModal = false }
                        }
                    
                    LeaveConfirmModal(showModal: $viewModel.showLeaveModal)
                        .zIndex(2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut.delay(0.1), value: viewModel.showLeaveModal)
                }
            }.ignoresSafeArea()
        }
    }
    
    private func headerLabelText() -> String {
        if viewModel.gameOver { return "Game over" }
        return "Scores after"
    }
    
    private func headerText() -> String {
        if viewModel.gameOver {
            let score = viewModel.scores.first!
            let player = viewModel.player(id: score.playerId)!
            return "\(player.name) wins"
        }
        
        return "Round \(viewModel.roundNumber)"
    }
    
    private func levelText(_ level: Int) -> String {
        if level == 11 { return "🏆" }
        return "(\(level))"
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
        
        viewModel.gameOver = true
        
        viewModel.remainingPlayers = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "af225f65-7e29-4f08-b1e2-ac67abec6ab0",
            "20fc38f2-8657-47ca-8b64-72e3cc021d77",
            "679fbdde-eafa-46de-bc40-40165f68b218"
        ]
        
        viewModel.players = [
            Player(name: "Christopher", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8"),
            Player(name: "Kira", id: "af225f65-7e29-4f08-b1e2-ac67abec6ab0"),
            Player(name: "Lily Jo", id: "20fc38f2-8657-47ca-8b64-72e3cc021d77"),
            Player(name: "Brett", id: "679fbdde-eafa-46de-bc40-40165f68b218"),
            Player(name: "Cari", id: "211a7eda-a033-46f7-9c9a-b98041380cd1"),
            Player(name: "John", id: "cc7a02b6-4cce-4436-bf24-c7523eb7172f")
        ]
        
        viewModel.playersReady = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "af225f65-7e29-4f08-b1e2-ac67abec6ab0"
        ]
        
        viewModel.scores = [
            Score(level: 11, playerId: "b95e86d7-82d5-4444-9322-2a7405f64fb8", points: 200),
            Score(level: 10, playerId: "af225f65-7e29-4f08-b1e2-ac67abec6ab0", points: 45),
            Score(level: 9, playerId: "20fc38f2-8657-47ca-8b64-72e3cc021d77", points: 120),
            Score(level: 8, playerId: "679fbdde-eafa-46de-bc40-40165f68b218", points: 165),
            Score(level: 8, playerId: "211a7eda-a033-46f7-9c9a-b98041380cd1", points: 240),
            Score(level: 7, playerId: "cc7a02b6-4cce-4436-bf24-c7523eb7172f", points: 285)
        ]
        
        return viewModel
    }
    
    static var previews: some View {
        ScoreView()
            .environmentObject(viewModel)
    }
}
