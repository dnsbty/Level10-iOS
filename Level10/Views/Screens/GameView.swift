//
//  GameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State var displayScores = false
    
    private var smallSize = DeviceTypes.ScreenSize.maxLength < 800
    
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
                VStack(alignment: .leading, spacing: smallSize ? 4 : 16) {
                    ForEach(viewModel.players) { player in
                        if viewModel.remainingPlayers.contains(player.id) {
                            HStack(spacing: smallSize ? 4 : 6) {
                                StatusIndicator(status: viewModel.isConnected(playerId: player.id) ? .online : .offline)
                                    .frame(width: 10, height: 10, alignment: .center)
                                
                                Text(player.id == UserManager.shared.id ? "You" : player.name)
                                    .font(.system(size: 18.0, weight: player.id == viewModel.currentPlayer ? .bold : .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .strikethrough(viewModel.skippedPlayers.contains(player.id))
                                    .underline(player.id == viewModel.currentPlayer)
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
                        .padding(smallSize ? .horizontal : .all)
                }
                
                // MARK: Player hand
                
                HStack {
                    if let newCard = viewModel.newCard {
                        Button {
                            if viewModel.isCurrentPlayer && viewModel.hasDrawn {
                                HapticManager.playSelectionChanged()
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
                                if viewModel.isCurrentPlayer && viewModel.hasDrawn {
                                    HapticManager.playSelectionChanged()
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
                .padding(.bottom)
            }
            
            // MARK: Error/warning banner
            
            ZStack(alignment: .top) {
                if let joinError = viewModel.error {
                    ErrorBanner(message: joinError, displaySeconds: 5, type: .warning) {
                        withAnimation { viewModel.error = nil }
                    }
                    .zIndex(1)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.error)
                }
            }
            
            // MARK: Modals
            
            ZStack(alignment: .bottom) {
                if let winner = viewModel.roundWinner {
                    Color(uiColor: .systemBackground)
                        .opacity(0.25)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showLeaveModal)
                        .background(.ultraThinMaterial)
                    
                    RoundCompleteModal(currentScreen: $viewModel.currentScreen,
                                       completedLevel: viewModel.completedLevel,
                                       gameOver: viewModel.gameOver,
                                       winner: winner)
                    .zIndex(1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showLeaveModal)
                } else if viewModel.selectPlayerToSkip {
                    Color(uiColor: .systemBackground)
                        .opacity(0.25)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showLeaveModal)
                        .background(.ultraThinMaterial)
                    
                    SkipSelectModal(displayModal: $viewModel.selectPlayerToSkip,
                                    players: viewModel.players,
                                    skippedPlayers: viewModel.skippedPlayers) { playerId in
                        viewModel.skipPlayer(id: playerId)
                    }
                    .zIndex(1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showLeaveModal)
                } else if viewModel.showLeaveModal {
                    Color(uiColor: .systemBackground)
                        .opacity(0.25)
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showLeaveModal)
                        .background(.ultraThinMaterial)
                        .onTapGesture {
                            withAnimation { viewModel.showLeaveModal = false }
                        }
                    
                    LeaveConfirmModal(showModal: $viewModel.showLeaveModal, midRound: true)
                        .zIndex(1)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut.delay(0.1), value: viewModel.showLeaveModal)
                }
            }.ignoresSafeArea()
            
            // MARK: Score Modal
            
            ZStack(alignment: .trailing) {
                if displayScores {
                    Color(uiColor: .systemBackground)
                        .opacity(0.25)
                        .transition(.opacity)
                        .animation(.easeInOut, value: displayScores)
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { displayScores = false }
                        }
                    
                    ScoreView(inModal: true)
                        .padding(.leading, 24)
                        .zIndex(1)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.easeInOut.delay(0.1), value: displayScores)
                }
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded({ value in
            if value.translation.width > 50 {
                withAnimation {
                    if displayScores {
                        displayScores = false
                    } else {
                        viewModel.showLeaveModal = true
                    }
                }
            } else if value.translation.width < -50 {
                withAnimation { displayScores = true }
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
        guard !viewModel.hasDrawn else {
            withAnimation { viewModel.error = "You can't draw twice in the same turn silly 😋" }
            return
        }
        
        HapticManager.playMediumImpact()
        
        Task {
            do {
                try await NetworkManager.shared.drawCard(source: source)
            } catch {
                withAnimation { viewModel.error = "An unexpected error occurred. Please try force quitting the app and then try again 🤯" }
            }
        }
        
    }
    
    private func onTapDiscardPile() {
        guard viewModel.currentPlayer == UserManager.shared.id else {
            withAnimation { viewModel.error = "Watch it bud! It's not your turn yet 😠" }
            return
        }
        
        guard viewModel.hasDrawn else {
            guard viewModel.discardPileTopCard != nil else {
                withAnimation { viewModel.error = "What are you trying to draw? The discard pile is empty... 🕵️‍♂️" }
                return
            }
            
            guard viewModel.discardPileTopCard!.value != .skip else {
                withAnimation { viewModel.error = "You can't draw a skip that has already been discarded 😂" }
                return
            }
            
            drawCard(source: .discardPile)
            return
        }
        
        guard viewModel.selectedCards.count == 1 else {
            withAnimation {
                if viewModel.selectedCards.count == 0 {
                    viewModel.error = "You need to select a card in your hand before you can discard it silly 😄"
                } else {
                    viewModel.error = "Nice try, but you can only discard one card at a time 🧐"
                }
            }
            return
        }
                
        if !viewModel.settings.skipNextPlayer,
           viewModel.selectedCards.first?.value == .skip {
            HapticManager.playLightImpact()
            withAnimation { viewModel.selectPlayerToSkip = true }
        } else {
            HapticManager.playMediumImpact()
            
            Task {
                do {
                    try await NetworkManager.shared.discardCard(card: viewModel.selectedCards.first!, playerToSkip: nil)
                } catch {
                    withAnimation { viewModel.error = "An unexpected error occurred. Please try force quitting the app and then try again 🤯" }
                }
            }
        }
    }
    
    private func onTapDrawPile() {
        guard viewModel.currentPlayer == UserManager.shared.id else {
            withAnimation { viewModel.error = "Watch it bud! It's not your turn yet 😠" }
            return
        }
        
        guard !viewModel.hasDrawn else {
            withAnimation { viewModel.error = "You can't draw twice in the same turn silly 😋" }
            return
        }
        
        drawCard(source: .drawPile)
    }
    
    private func onTapPlayerTable(playerId: String, groupIndex: Int) {
        if !viewModel.completedLevel && playerId == UserManager.shared.id {
            onTapSelfTable(groupIndex: groupIndex)
        } else {
            viewModel.addToPlayerTable(playerId: playerId, index: groupIndex)
        }
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
            Player(name: "Kira", id: "64d7f3b7-390e-4948-849e-a8745174db0e"),
            Player(name: "Lily", id: "13c059c6-f4ad-4b05-87ca-2a61390f9042"),
            Player(name: "Brett", id: "eb180f94-a899-4915-b2e8-57b8ea3e6103"),
            Player(name: "Danny", id: "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c"),
            Player(name: "Megan", id: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4")
        ]
        viewModel.levels = [
            "b95e86d7-82d5-4444-9322-2a7405f64fb8": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 4, type: .run)
            ]),
            "64d7f3b7-390e-4948-849e-a8745174db0e": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 4, type: .run)
            ]),
            "13c059c6-f4ad-4b05-87ca-2a61390f9042": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 4, type: .run)
            ]),
            "eb180f94-a899-4915-b2e8-57b8ea3e6103": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 3, type: .set)
            ]),
            "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c": Level(groups: [
                LevelGroup(count: 3, type: .set), LevelGroup(count: 3, type: .set)
            ]),
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": Level(groups: [
                LevelGroup(count: 7, type: .run)
            ])
        ]
        viewModel.connectedPlayers = [
            "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c",
            "13c059c6-f4ad-4b05-87ca-2a61390f9042",
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "eb180f94-a899-4915-b2e8-57b8ea3e6103"
        ]
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
            "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c": 10,
            "13c059c6-f4ad-4b05-87ca-2a61390f9042": 10,
            "64d7f3b7-390e-4948-849e-a8745174db0e": 10,
            "b95e86d7-82d5-4444-9322-2a7405f64fb8": 10,
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4": 2,
            "eb180f94-a899-4915-b2e8-57b8ea3e6103": 10
        ]
        viewModel.newCard = Card(color: .blue, value: .three)
        viewModel.remainingPlayers = [
            "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c",
            "13c059c6-f4ad-4b05-87ca-2a61390f9042",
            "64d7f3b7-390e-4948-849e-a8745174db0e",
            "b95e86d7-82d5-4444-9322-2a7405f64fb8",
            "cf34b6bf-b452-400a-a7f3-d5537d5a73b4",
            "eb180f94-a899-4915-b2e8-57b8ea3e6103"
        ]
        viewModel.scores = [
            Score(level: 11, playerId: "b95e86d7-82d5-4444-9322-2a7405f64fb8", points: 200),
            Score(level: 10, playerId: "036a85e5-2b00-4cb7-8407-ca4b74ff4c7c", points: 45),
            Score(level: 9, playerId: "13c059c6-f4ad-4b05-87ca-2a61390f9042", points: 120),
            Score(level: 8, playerId: "64d7f3b7-390e-4948-849e-a8745174db0e", points: 165),
            Score(level: 8, playerId: "cf34b6bf-b452-400a-a7f3-d5537d5a73b4", points: 240),
            Score(level: 7, playerId: "eb180f94-a899-4915-b2e8-57b8ea3e6103", points: 285)
        ]
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
