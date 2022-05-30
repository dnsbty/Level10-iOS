//
//  CardView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct CardBackView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.white, lineWidth: 5.5)
                .background { RoundedRectangle(cornerRadius: 13).foregroundColor(.slate900) }
            
            Text("Level 10")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.violet700)
                .rotationEffect(Angle(degrees: 55))
                .offset(x: 2, y: 2)
            
            Text("Level 10")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .violet700, radius: 1)
                .rotationEffect(Angle(degrees: 55))
        }
        .frame(width: 80, height: 112)
    }
}

struct CardView: View {
    var card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.white, lineWidth: 5.5)
                .background { RoundedRectangle(cornerRadius: 13).foregroundColor(color(card: card)) }
            
            Text(displayText(card: card))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
        }
        .frame(width: 80, height: 112)
    }
    
    private func color(card: Card) -> Color {
        switch card.color {
        case .red:
            return .red500
        case .yellow:
            return .yellow500
        case .green:
            return .green600
        case .blue:
            return .sky600
        case .black:
            return .slate900
        }
    }
    
    private func displayText(card: Card) -> String {
        switch card.value {
        case .one:
            return "1"
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        case .six:
            return "6"
        case .seven:
            return "7"
        case .eight:
            return "8"
        case .nine:
            return "9"
        case .ten:
            return "10"
        case .eleven:
            return "11"
        case .twelve:
            return "12"
        case .skip:
            return "S"
        case .wild:
            return "W"
        }
    }
    
    private func readableText(card: Card) -> String {
        var readableText: String
        
        switch card.color {
        case .red:
            readableText = "red "
        case .yellow:
            readableText = "yellow "
        case .green:
            readableText = "green "
        case .blue:
            readableText = "blue "
        case .black:
            readableText = ""
        }
        
        switch card.value {
        case .skip:
            readableText += "skip"
        case .wild:
            readableText += "wild"
        default:
            readableText += displayText(card: card)
        }
        
        return readableText
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardBackView()
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .black, value: .wild))
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .red, value: .one))
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .yellow, value: .two))
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .green, value: .ten))
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .blue, value: .twelve))
        }
        .previewLayout(PreviewLayout.fixed(width: 100, height: 128))
        
        ZStack {
            Color.violet700.edgesIgnoringSafeArea(.all)
            
            CardView(card: Card(color: .black, value: .skip))
                .scaleEffect(2.0)
        }
        .previewLayout(PreviewLayout.fixed(width: 200, height: 256))
    }
}
