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
            
            // MARK: Player tables
            
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.players) { player in
                        HStack(spacing: 6) {
                            StatusIndicator(status: viewModel.isConnected(playerId: player.id) ? .online : .offline)
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
                                .frame(width: 16)
                            
                            self.playerTable(player.id)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // MARK: Draw and discard piles
                
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
                
                // MARK: Player table
                
                if !viewModel.completedLevel {
                    self.ownTable()
                        .frame(maxHeight: 100)
                        .padding()
                }
                
                // MARK: Player hand
                
                HStack {
                    if let newCard = viewModel.newCard {
                        Button {
                            if viewModel.isCurrentPlayer {
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
                                if viewModel.isCurrentPlayer {
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
                    .frame(width: 296)
                }
                .padding(.horizontal)
            }
            
            if let winner = viewModel.roundWinner {
                ZStack(alignment: .bottom) {
                    Color(uiColor: .systemBackground).opacity(0.8)
                    
                    RoundCompleteModal(currentScreen: $viewModel.currentScreen,
                                       completedLevel: viewModel.completedLevel,
                                       winner: winner)
                }.ignoresSafeArea()
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded({ value in
            if value.translation.width > 50 {
                NetworkManager.shared.leaveGame()
            }
        }))
    }
    
    private func playerTable(_ playerId: String) -> some View {
        HStack(spacing: 6) {
            let levelGroups = viewModel.levelGroups(player: playerId)
            
            if let playerTable = viewModel.table[playerId] {
                ForEach(levelGroups.indices, id: \.self) { index in
                    let group = playerTable[index]
                    
                    Button {
                        onTapPlayerTable(playerId: playerId, groupIndex: index)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.violet900)
                                .overlay {
                                    GeometryReader { geometry in
                                        HStack(spacing: -1) {
                                            ForEach(group.indices, id: \.self) { cardIndex in
                                                CardView(card: group[cardIndex])
                                                    .scaleEffect(0.25)
                                                    .frame(width: (geometry.size.width - 10) / CGFloat(group.count))
                                            }
                                        }
                                        .frame(width: geometry.size.width - 20, height: 40)
                                        .padding(.horizontal, 10)
                                    }
                                }
                        }
                        .frame(height: 40)
                    }
                }
            } else {
                ForEach(levelGroups.indices, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.violet900)
                        
                        Text(levelGroups[i].toString())
                            .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                            .foregroundColor(.violet300)
                    }
                    .frame(height: 40)
                }
            }
        }
    }
    
    private func ownTable() -> some View {
        HStack(spacing: 6) {
            let levelGroups = viewModel.levelGroups(player: UserManager.shared.id ?? "b95e86d7-82d5-4444-9322-2a7405f64fb8")
            
            ForEach(levelGroups.indices, id: \.self) { index in
                Button {
                    onTapSelfTable(groupIndex: index)
                } label: {
                    if let group = viewModel.tempTable[index] {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.violet900)
                                .overlay {
                                    VStack(spacing: 2) {
                                        Text(levelGroups[index].toString())
                                            .font(.system(size: 14.0, weight: .regular , design: .rounded))
                                            .foregroundColor(.violet300)
                                            .padding(.top, 4)
                                        
                                        GeometryReader { geometry in
                                            HStack(spacing: group.count >= 12 || group.count < 5 ? -3 : -4) {
                                                ForEach(group.indices, id: \.self) { cardIndex in
                                                    CardView(card: group[cardIndex])
                                                        .scaleEffect(0.5)
                                                        .frame(width: (geometry.size.width - 10) / CGFloat(group.count))
                                                }
                                            }
                                            .frame(width: geometry.size.width - 20, height: 60)
                                            .padding(.horizontal, 10)
                                        }
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            viewModel.clearTempTableGroup(index)
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .frame(width: 18, height: 18)
                                                    .foregroundColor(.violet400)
                                                
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.violet900)
                                                    .imageScale(.small)
                                                    .frame(width: 14, height: 14)
                                            }
                                            .padding(2)
                                            .frame(width: 44, height: 44)
                                            .offset(x: 10, y: -10)
                                        }
                                    }
                                }
                        }
                        .frame(height: 90)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(.violet900)
                            
                            Text(levelGroups[index].toString())
                                .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.violet300)
                        }
                        .frame(height:90)
                    }
                }
            }
        }
    }
    
    private func tabledGroupSpacing(cardCount: Int) -> CGFloat {
        switch cardCount {
        case 2: return -100
        case 3: return -65
        case 4: return -48
        case 5: return -40
        case 6: return -34
        case 7: return -30
        case 8: return -27
        case 9: return -24
        case 10: return -22
        case 11: return -20
        default: return CGFloat(-30 + cardCount)
        }
    }
    
    private func tabledCardFrameWidth(screenWidth: CGFloat, groupCount: Int, cardCount: Int) -> CGFloat {
        return (screenWidth - 100 / CGFloat(groupCount)) / CGFloat(cardCount)
    }
    
    private func drawCard(source: DrawSource) {
        guard !viewModel.hasDrawn else { return }
        
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
            if viewModel.selectedCards.count == 1 {
                Task {
                    do {
                        try await NetworkManager.shared.discardCard(card: viewModel.selectedCards.first!)
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
            drawCard(source: .discardPile)
        }
    }
    
    private func onTapDrawPile() {
        guard viewModel.currentPlayer == UserManager.shared.id,
              !viewModel.hasDrawn
        else { return }
        
        drawCard(source: .drawPile)
    }
    
    private func onTapPlayerTable(playerId: String, groupIndex: Int) {
        viewModel.addToPlayerTable(playerId: playerId, index: groupIndex)
    }
    
    private func onTapSelfTable(groupIndex: Int) {
        guard viewModel.currentPlayer == UserManager.shared.id else { return }
        guard viewModel.selectedIndices.count > 0 || viewModel.newCardSelected else { return }
        viewModel.addToTable(groupIndex)
    }
}

struct GameView_Previews: PreviewProvider {
    static var viewModel: GameViewModel {
        let viewModel = GameViewModel()
        viewModel.currentPlayer = "b95e86d7-82d5-4444-9322-2a7405f64fb8"
        viewModel.players = [
            Player(name: "Dennis", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8"),
            Player(name: "Player 1", id: "1"),
            Player(name: "Dennis", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4"),
            Player(name: "Dennis", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4"),
            Player(name: "Dennis", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4"),
            Player(name: "Brett", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4")
        ]
        viewModel.levels = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 4, type: .run)
            ]),
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 3, type: .set)
            ]),
            "1": Level(groups: [
                LevelGroup(count: 7, type: .run)
            ])
        ]
        viewModel.connectedPlayers = ["b95e86d7-82d5-4444-9322-2a7405f64fb8", "1"]
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
        viewModel.handCounts = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8": 10,
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": 2,
            "1": 3
        ]
        viewModel.newCard = Card(color: .blue, value: .three)
        viewModel.table = [
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": [
                [
                    Card(color: .black, value: .wild),
                    Card(color: .green, value: .three),
                    Card(color: .blue, value: .three)
                ],
                [
                    Card(color: .red, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .yellow, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .green, value: .one),
                    Card(color: .red, value: .one)
                ]
            ]
        ]
        viewModel.tempTable = [
            1: [
                Card(color: .red, value: .one),
                Card(color: .yellow, value: .two),
                Card(color: .green, value: .three),
                Card(color: .blue, value: .four),
                Card(color: .black, value: .five),
                Card(color: .red, value: .six),
                Card(color: .yellow, value: .seven),
                Card(color: .green, value: .eight),
                Card(color: .blue, value: .nine),
                Card(color: .black, value: .ten),
                Card(color: .red, value: .eleven),
                Card(color: .yellow, value: .twelve)
            ]
        ]
//        viewModel.roundWinner = Player(name: "Dennis", id: "b95e86d7-82d5-4444-9322-2a7405f64fb8")
        return viewModel
    }
    
    static var previews: some View {
        GameView()
            .environmentObject(viewModel)
    }
}
