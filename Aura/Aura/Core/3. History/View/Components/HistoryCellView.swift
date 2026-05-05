//
//  HistoryCellView.swift
//  Aura
//
//  Created by ddorsat on 07.05.2026.
//

import SwiftUI

struct HistoryCellView: View {
    @State private var isSelected = false
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 15) {
                Text("♑️")
                    .font(.title2)
                    .padding(10)
                    .background(LinearGradient(colors: [.softPurple, .idealPartnerType1], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle() .stroke(.white, lineWidth: 2))
                    .clipShape(Circle())
                    .shadow(radius: 1)
                    .padding(.top, 5)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Мария")
                            .bold()
                        
                        Spacer()
                        
                        Text("94%")
                            .font(.footnote)
                            .foregroundStyle(.deepBlue)
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(.capsuleBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Text("Глубоко гармоничный расклад. Глубокая интеллектуальная синергия с общими долгосрочными взглядами.")
                        .font(.callout)
                        .foregroundStyle(.deepGray)
                }
            }
        }
        .padding()
        .backgroundWithShape(15, true)
    }
}

#Preview {
    HistoryCellView()
}
