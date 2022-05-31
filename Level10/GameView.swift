//
//  GameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    private var gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.violet700.ignoresSafeArea()
            
            VStack {
                VStack(alignment: .leading) {
                    ForEach(viewModel.players) { player in
                        HStack(spacing: 6) {
                            StatusIndicator(status: viewModel.connectedPlayers.contains(player.id) ? .online : .offline)
                                .frame(width: 10, height: 10, alignment: .center)
                            
                            Text(player.id == UserManager.shared.id ? "You" : player.name)
                                .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: 100, alignment: .leading)
                                .opacity(player.id == viewModel.currentPlayer ? 1.0 : 0.6)
                        
                            Spacer()
                            
                            let handCount = viewModel.handCounts[player.id]
                            Text("\(handCount == nil ? "" : "\(handCount!)")")
                                .font(.system(size: 12.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.violet300)
                            
                            HStack(spacing: 6) {
                                let levelGroups = viewModel.levelGroups(player: player.id)
                                ForEach(levelGroups.indices, id: \.self) { i in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .foregroundColor(.violet900)
                                        
                                        Text(levelGroups[i].toString())
                                            .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                                            .foregroundColor(.violet300)
                                    }
                                }
                            }
                            .frame(height: 38)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        onTapDrawPile()
                    } label: {
                        CardBackView()
                    }
                    
                    Spacer()
                    
                    Button {
                        onTapDiscardPile()
                    } label: {
                        if let discardTop = viewModel.discardPileTopCard {
                            CardView(card: discardTop)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13)
                                    .strokeBorder(Color.violet400)
                                
                                Text("Discard Pile")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.violet400)
                            }
                            .frame(width: 80, height: 112)
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    let levelGroups = viewModel.levelGroups(player: UserManager.shared.id ?? "")
                    ForEach(levelGroups.indices, id: \.self) { i in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.violet900)
                            
                            Text(levelGroups[i].toString())
                                .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.violet300)
                        }
                    }
                }
                .frame(height: 74)
                .padding()
                
                HStack {
                    if let newCard = viewModel.newCard {
                        Button {
                            if viewModel.currentPlayer == UserManager.shared.id {
                                viewModel.newCardSelected = !viewModel.newCardSelected
                            }
                        } label: {
                            CardView(card: newCard)
                                .overlay { viewModel.newCardSelected ? RoundedRectangle(cornerRadius: 13).fill(.white).opacity(0.5) : nil }
                                .scaleEffect(0.65)
                                .frame(width: 54, height: 74)
                        }
                    }
                    
                    LazyVGrid(columns: gridItemLayout, spacing: 8.0) {
                        ForEach(viewModel.hand.indices, id: \.self) { i in
                            Button {
                                if viewModel.currentPlayer == UserManager.shared.id {
                                    viewModel.toggleIndexSelected(i)
                                }
                            } label: {
                                CardView(card: viewModel.hand[i])
                                    .overlay { viewModel.selectedIndices.contains(i) ? RoundedRectangle(cornerRadius: 13).fill(.white).opacity(0.5) : nil }
                                    .scaleEffect(0.65)
                                    .frame(width: 54, height: 74)
                            }
                        }
                    }
                    .frame(width: 302)
                }
                .padding(.horizontal)
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded({ value in
            if value.translation.width > 0 {
                NetworkManager.shared.leaveGame()
            }
        }))
    }
    
    private func drawCard(source: DrawSource) {
        Task {
            do {
                try await NetworkManager.shared.drawCard(source: source)
            } catch {
                // TODO: Display the errors returned here
                print("Error drawing card")
            }
        }
        
    }
    
    private func onTapDiscardPile() {
        guard viewModel.currentPlayer == UserManager.shared.id else {
            // TODO: Display error
            return
        }
        
        if viewModel.hasDrawn {
            if viewModel.selectedIndices.count == 0 && viewModel.newCardSelected {
                Task {
                    do {
                        try await NetworkManager.shared.discardCard(card: viewModel.newCard!)
                    } catch {
                        // TODO: Display errors returned here
                        print("Error discarding card")
                    }
                }
            } else if viewModel.selectedIndices.count == 1 && !viewModel.newCardSelected {
                let index = viewModel.selectedIndices.first!
                let card = viewModel.hand[index]
                Task {
                    do {
                        try await NetworkManager.shared.discardCard(card: card)
                    } catch {
                        // TODO: Display errors returned here
                        print("Error discarding card")
                    }
                }
            } else {
                // TODO: Display error
                return
            }
        } else {
            print("Drawing card from discard pile")
            drawCard(source: .discardPile)
        }
    }
    
    private func onTapDrawPile() {
        guard viewModel.currentPlayer == UserManager.shared.id else {
            // TODO: Display error
            return
        }
        
        if viewModel.hasDrawn {
            // TODO: Display error
            return
        } else {
            drawCard(source: .drawPile)
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var viewModel: GameViewModel {
        let viewModel = GameViewModel()
        viewModel.currentPlayer = "b95e86d7-82d5-4444-9322-2a7405f64fb8"
        viewModel.players = [
            Player(name: "Dennis", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8"),
            Player(name: "Brett", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4")
        ]
        viewModel.levels = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 4, type: .run)
            ]),
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 3, type: .set)
            ])
        ]
        viewModel.connectedPlayers = ["b95e86d7-82d5-4444-9322-2a7405f64fb8"]
        viewModel.hand = [
            Card(color: .black, value: .wild),
            Card(color: .black, value: .wild),
            Card(color: .red, value: .one),
            Card(color: .green, value: .four),
            Card(color: .yellow, value: .four),
            Card(color: .blue, value: .eight),
            Card(color: .green, value: .eight),
            Card(color: .green, value: .eleven),
            Card(color: .yellow, value: .twelve),
            Card(color: .black, value: .skip)
        ]
        viewModel.newCard = Card(color: .blue, value: .three)
        return viewModel
    }
    
    static var previews: some View {
        GameView()
            .environmentObject(viewModel)
    }
}
