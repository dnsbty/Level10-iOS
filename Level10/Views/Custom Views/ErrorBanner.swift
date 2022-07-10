//
//  ErrorBanner.swift
//  Level10
//
//  Created by Dennis Beatty on 7/9/22.
//

import SwiftUI

struct ErrorBanner: View {
    @State var progress: Double = 0
    @State var tick = 0.0
    
    let fps = 60.0
    let finalTick: Double
    let message: String
    let onClose: (() -> ())
    let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()
    
    init(message: String, displaySeconds: Double, onClose: @escaping (() -> ())) {
        finalTick = round(displaySeconds * fps)
        self.message = message
        self.onClose = onClose
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .lineSpacing(2.0)
                    .foregroundColor(.white)
                    .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                    .shadow(color: .red700, radius: 2, x: 0, y: 2)
                    .padding(.horizontal)

                Button {
                    onClose()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut, value: progress)
                            .frame(width: 32, height: 32)

                        Image(systemName: "xmark")
                            .font(Font.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red500)
            .shadow(color: .red700, radius: 8.0, x: 0, y: 0)
            
            Spacer()
        }
        .onReceive(timer) { _ in
            if tick < finalTick {
                tick = tick + 1
                progress = tick / finalTick
            } else {
                onClose()
            }
        }
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    @State var showError = true
    static var viewModel: GameViewModel {
        let viewModel = GameViewModel()
        viewModel.error = "That join code doesn't exist. Are you trying to hack the game? 🤨"
        return viewModel
    }
    
    static var previews: some View {
        ZStack(alignment: .top) {
            JoinGameView(displayName: "Dennis", joinCode: "ABCD")
                .environmentObject(viewModel)
            
            ErrorBanner(message: "That join code doesn't exist. Let's make this a lot longer to Are you trying to hack the game? 🤨",
                        displaySeconds: 5) {}
        }
    }
}
