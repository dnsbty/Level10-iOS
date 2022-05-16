//
//  GameView.swift
//  Level10
//
//  Created by Dennis Beatty on 5/15/22.
//

import SwiftUI

struct GameView: View {
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
                    ForEach(0..<6) { _ in
                        HStack(spacing: 6) {
                            StatusIndicator(status: .offline)
                                .frame(width: 10, height: 10, alignment: .center)
                            
                            Text("Christopher")
                                .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: 100)
                        
                            Spacer()
                            
                            Text("10")
                                .font(.system(size: 12.0, weight: .semibold, design: .rounded))
                                .foregroundColor(.violet300)
                            
                            HStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.violet900)
                                    
                                    Text("Set of 3")
                                        .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                                        .foregroundColor(.violet300)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.violet900)
                                    
                                    Text("Set of 3")
                                        .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                                        .foregroundColor(.violet300)
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
                    CardBackView()
                    Spacer()
                    CardView(card: Card(color: .red, value: .twelve))
                    Spacer()
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.violet900)
                        
                        Text("Set of 3")
                            .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                            .foregroundColor(.violet300)
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.violet900)
                        
                        Text("Set of 3")
                            .font(.system(size: 16.0, weight: .semibold, design: .rounded))
                            .foregroundColor(.violet300)
                    }
                    
                }
                .frame(height: 74)
                .padding()
                
                HStack {
//                    CardView(card: Card(color: .black, value: .wild))
//                        .scaleEffect(0.65)
//                        .frame(width: 54, height: 74)
                    
                    LazyVGrid(columns: gridItemLayout, spacing: 8.0) {
                        CardView(card: Card(color: .black, value: .wild))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .black, value: .wild))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .red, value: .one))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .green, value: .four))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .yellow, value: .four))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .blue, value: .eight))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .green, value: .eight))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .green, value: .eleven))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .yellow, value: .twelve))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                        
                        CardView(card: Card(color: .black, value: .skip))
                            .scaleEffect(0.65)
                            .frame(width: 54, height: 74)
                    }
                    .frame(width: 302)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
