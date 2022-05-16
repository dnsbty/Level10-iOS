//
//  L10TextField.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct L10TextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.violet200)
            .cornerRadius(8.0)
            .foregroundColor(.slate700)
            .font(.system(size: 22.0, weight: .semibold, design: .rounded))
    }
}

struct L10TextField: View {
    var labelText: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(labelText)
                .font(.system(size: 20.0, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            TextField("", text: $value)
        }
        .textFieldStyle(L10TextFieldStyle())
    }
}

struct L10TextField_Previews: PreviewProvider {
    static var previews: some View {
        L10TextField(labelText: "Display Name", value: .constant("Dennis"))
            .previewLayout(PreviewLayout.fixed(width: 358, height: 94))
            .background { Color.violet700 }
    }
}
