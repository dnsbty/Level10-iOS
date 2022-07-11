//
//  L10Button.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

enum ButtonType {
    case primary, secondary, ghost
    
    var bgColor: Color {
        switch self {
        case .primary:
            return .red500
        case .secondary:
            return .violet400
        case .ghost:
            return .black.opacity(0)
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary:
            return .red700.opacity(0.25)
        case .secondary:
            return .violet900.opacity(0.25)
        case .ghost:
            return .black.opacity(0)
        }
    }
    
    var textColor: Color {
        switch self {
        case .ghost:
            return .violet300
        default:
            return .white
        }
    }
    
    var textShadownColor: Color {
        switch self {
        case .primary:
            return .red600
        case .secondary:
            return .violet400
        case .ghost:
            return .violet300.opacity(0.25)
        }
    }
}

struct L10Button: View {
    var text: String
    var type: ButtonType
    var disabled = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18.0)
                .foregroundColor(type.bgColor)
            
            Text(text)
                .strikethrough(disabled && type != .primary)
                .font(.system(size: 24.0, weight: .bold, design: .rounded))
                .foregroundColor(type.textColor)
                .shadow(color: type.textShadownColor, radius: 4, x: 0, y: 4)
        }
        .frame(height: 58)
        .shadow(color: type.shadowColor, radius: 4, x: 0, y: 4)
        .opacity(disabled ? 0.4 : 1.0)
    }
}

struct L10Button_Previews: PreviewProvider {
    static var previews: some View {
        L10Button(text: "Join Game", type: .primary)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
        
        L10Button(text: "Join Game", type: .primary, disabled: true)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
        
        L10Button(text: "Create Game", type: .secondary)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
        
        L10Button(text: "Create Game", type: .secondary, disabled: true)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
        
        L10Button(text: "Nevermind", type: .ghost)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
        
        L10Button(text: "Nevermind", type: .ghost, disabled: true)
            .previewLayout(PreviewLayout.fixed(width: 358, height: 58))
            .background { Color.violet700 }
    }
}
