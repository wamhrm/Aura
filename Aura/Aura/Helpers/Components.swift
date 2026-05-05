//
//  Components.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI

struct Components {
    static func backgroundColor() -> some View {
        return Color(uiColor: .appBackground).ignoresSafeArea()
    }
    
    static func horoscopeDate(_ isCellDetails: Bool) -> some View {
        HStack(spacing: 7) {
            Text("5 мая")
            
            Rectangle()
                .frame(width: isCellDetails ? 10 : 5, height: 1)
            
            Text("12 мая")
        }
        .font(.footnote)
        .fontWeight(isCellDetails ? .bold : .medium)
        .foregroundStyle(.deepGray)
        .frame(maxWidth: isCellDetails ? 115 : .infinity, alignment: isCellDetails ? .center : .leading)
    }
    
    static func sparkleImage(_ size: Image.Scale, _ padding: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .padding(.top, 10)
            .foregroundStyle(.white)
            .padding(padding)
    }
    
    static func sparkImageWithBackground(_ size: Image.Scale, _ color: Color) -> some View {
        Image(systemName: "sparkles")
            .imageScale(size)
            .foregroundStyle(color)
            .padding(8)
            .background(Color(.systemGray6).opacity(0.15))
            .clipShape(Circle())
    }
    
    static func logoImage(_ size: CGFloat) -> some View {
        Image("logo")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .clipped()
    }
    
    static func completeYourProfile(_ completion: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Заполните свой профиль")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(.white)
                }
                
                Text("Расскажите о себе, чтобы получить детальный разбор вашего астрологического профиля")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            Button {
                completion()
            } label: {
                Text("Заполнить информацию")
                    .foregroundStyle(Color(red: 0.42, green: 0.27, blue: 0.93))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0.42,
                                                  green: 0.27,
                                                  blue: 0.93),
                                            Color(red: 0.62,
                                                  green: 0.33,
                                                  blue: 0.95)],
                                   startPoint: .leading,
                                   endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    static func classicButton(_ title: String, _ completion: @escaping () -> Void) -> some View {
        Button {
            completion()
        } label: {
            Text(title)
                .foregroundStyle(.white)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(LinearGradient(colors: [.blue, .blue.opacity(0.65)],
                                           startPoint: .leading,
                                           endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    static func testCellImage(_ title: String, _ color: UIColor, _ imgSize: Font, _ backgroundSize: CGFloat, _ isResults: Bool) -> some View {
        Image(systemName: title)
            .font(imgSize)
            .foregroundStyle(Color(color))
            .padding(10)
            .frame(width: backgroundSize, height: backgroundSize)
            .background(RoundedRectangle(cornerRadius: isResults ? 10 : 15) .fill(Color(color).opacity(0.2)))
    }
    
    static func completeYourProfileLock(_ title: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "lock")
                .imageScale(.large)
                .fontWeight(.semibold)
                .foregroundStyle(.deepGray)
                .padding()
                .background(Color(.systemGray6).opacity(0.75))
                .clipShape(Circle())
                .overlay(Circle() .stroke(Color(.systemGray5), lineWidth: 1))
            
            Text(title)
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    static func emotionalProfileBar(_ type: EmotionalProfileTypes, _ value: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(type.leftSide)
                
                Spacer()
                
                Text(type.rightSide)
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.deepGray)
            
            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray6))
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .softPurple],
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: bar.size.width * (CGFloat(value) / CGFloat(10)))
                }
            }
            .frame(height: 10)
        }
    }
    
    enum EmotionalProfileTypes {
        case temperament, thinking, organization, relationships
        
        var leftSide: String {
            switch self {
                case .temperament:
                    return "Интроверсия"
                case .thinking:
                    return "Логика"
                case .organization:
                    return "Хаос"
                case .relationships:
                    return "Независимость"
            }
        }
        
        var rightSide: String {
            switch self {
                case .temperament:
                    return "Экстраверсия"
                case .thinking:
                    return "Интуиция"
                case .organization:
                    return "Контроль"
                case .relationships:
                    return "Привязанность"
            }
        }
    }
}

struct SelectionButtons<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    @State private var selected: T
    let onTapHandler: (T) -> Void
    
    init(selected: T = T.allCases.first!, onTapHandler: @escaping (T) -> Void) {
        self._selected = State(initialValue: selected)
        self.onTapHandler = onTapHandler
    }
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(Array(T.allCases), id: \.self) { item in
                Button {
                    selected = item
                    onTapHandler(item)
                } label: {
                    Text(item.rawValue)
                        .font(.callout)
                        .foregroundStyle(selected == item ? .white : .deepGray)
                        .bold()
                        .frame(width: 110, height: 37)
                        .background(selected == item ? .deepBlue : .clear)
                        .overlay(RoundedRectangle(cornerRadius: 10) .stroke(.gray, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
