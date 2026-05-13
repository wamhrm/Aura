//
//  CompatibilityResultsView.swift
//  Aura
//
//  Created by ddorsat on 13.05.2026.
//

import SwiftUI

struct CompatibilityResultsView: View {
    var body: some View {
        ZStack {
            Components.backgroundColor()

            ScrollView {
                VStack(spacing: 15) {
                    compatibilityScaleBar(75)
                        .padding(.vertical)

                    HStack(spacing: 75) {
                        VStack {
                            Text("♑️")
                                .padding(10)
                                .background(.deepBlue.opacity(0.25))
                                .clipShape(Circle())

                            Text("Роберт")
                                .bold()
                        }
                        .frame(width: 150, alignment: .trailing)

                        VStack {
                            Text("♑️")
                                .padding(10)
                                .background(.purple.opacity(0.25))
                                .clipShape(Circle())

                            Text("Мария")
                                .bold()
                        }
                        .frame(width: 150, alignment: .leading)
                    }
                    .font(.title3)
                    .overlay {
                        Image(systemName: "heart")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                    
                    VStack(spacing: 10) {
                        Text("Интенсивная, но стабильная связь")
                            .foregroundStyle(.deepBlue)
                            .bold()
                        
                        Text("Вы ищете близость. Они защищают дистанцию.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                    .padding(.bottom, 10)
                    
                    Components.resultsSection("Основная динамика") {
                        Text("Между вами нет хаоса ради эмоций — связь строится на ощущении надёжности, уважения и внутреннего спокойствия. Вы оба не любите дешёвую драму, но из-за этого иногда избегаете сложных разговоров, пока напряжение не накопится.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                    }
                    
                    Components.resultsSection("Поведенческие паттерны") {
                        Text("Вы оба замечаете изменения в настроении партнёра раньше, чем он сам успевает об этом сказать.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            TestResultCellView(test: CompatibilityCellTypes.dominanceDynamics, description: "В отношениях нет явного лидера — влияние постоянно переходит от одного к другому.")
                            
                            Divider()
                            
                            TestResultCellView(test: CompatibilityCellTypes.emotionalResonance, description: "Вы быстро считываете эмоциональное состояние друг друга даже в тишине.")
                        }
                        .testTopicsModifier()
                    }
                    
                    Components.resultsSection("Эмоциональная совместимость") {
                        VStack(spacing: 15) {
                            Components.emotionalProfileBar(.emotionalResonance, 3)
                            Components.emotionalProfileBar(.innerOpenness, 7)
                            Components.emotionalProfileBar(.soulAlignment, 5)
                            Components.emotionalProfileBar(.emotionalWarmth, 9)
                        }
                        .padding(.top, 5)
                    }
                    
                    Components.resultsSection("Стили привязанности") {
                        Text("Привязанность между вами развивается медленно, но становится очень устойчивой со временем.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            TestResultCellView(test: CompatibilityCellTypes.attachmentBond, description: "Оба стремятся к стабильности и плохо переносят эмоциональную неопределённость.")
                            
                            Divider()
                            
                            TestResultCellView(test: CompatibilityCellTypes.comfortDistance, description: "Вам комфортно рядом даже без постоянного общения или подтверждения чувств.")
                        }
                        .testTopicsModifier()
                    }
                    
                    Components.resultsSection("Языки любви") {
                        Text("Ваши способы проявлять любовь отличаются, но хорошо дополняют друг друга.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            TestResultCellView(test: CompatibilityCellTypes.languageMatch, description: "Один показывает любовь через заботу и действия, другой — через внимание и эмоциональное присутствие.")
                            
                            Divider()
                            
                            TestResultCellView(test: CompatibilityCellTypes.translationNeeds, description: "Иногда вам нужно буквально проговаривать чувства, а не ожидать, что партнёр всё поймёт сам.")
                        }
                        .testTopicsModifier()
                    }
                    
                    Components.resultsSection("Конфликты и примерение") {
                        Text("Конфликты между вами редко бывают громкими, но могут затягиваться из-за упрямства.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            TestResultCellView(test: CompatibilityCellTypes.conflictMechanics, description: "Во время ссор вы оба уходите в себя вместо того, чтобы обсуждать проблему сразу.")
                            
                            Divider()
                            
                            TestResultCellView(test: CompatibilityCellTypes.peaceRecovery, description: "После конфликтов связь восстанавливается через спокойный контакт, а не через бурные извинения.")
                        }
                        .testTopicsModifier()
                    }
                    
                    Components.resultsSection("Сексуальная совместимость") {
                        Text("Физическое притяжение строится не только на страсти, но и на чувстве эмоциональной безопасности.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            TestResultCellView(test: CompatibilityCellTypes.sexualTemperament, description: "Ваш ритм близости совпадает: ни один не чувствует давления или эмоционального холода.")
                            
                            Divider()
                            
                            TestResultCellView(test: CompatibilityCellTypes.sexualChemistry, description: "Между вами сильная тактильная связь — прикосновения быстро снимают напряжение.")
                        }
                        .testTopicsModifier()
                    }
                    
                    Components.resultsSection("Прогноз будущего") {
                        Text("Если вы научитесь обсуждать сложные вещи сразу, а не копить их внутри, эта связь может стать одной из самых стабильных в вашей жизни.")
                            .font(.callout)
                            .foregroundStyle(.deepGray)
                        
                        VStack(spacing: 12) {
                            Components.resultsWithNumbersSection(.spark, "Редкое узнавание", "С самого начала возникло ощущение, будто вы уже давно знакомы друг с другом.")
                            
                            Components.resultsWithNumbersSection(.potentional, "Стабильный союз", "У этой связи высокий потенциал для долгих отношений без эмоциональных качелей.")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Результат теста на совместимость")
        .navigationBarTitleDisplayMode(.inline)
        .bottomAreaPadding()
    }
}

extension CompatibilityResultsView {
    private func compatibilityScaleBar(_ value: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Color.deepBlue.opacity(0.18), lineWidth: 10)

            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(Color.deepBlue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 5) {
                Text("\(min(max(value, 0), 100))%")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.deepBlue)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("СОВМЕСТИМОСТЬ")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.deepGray)
            }
        }
        .frame(width: 150, height: 150)
    }
}

#Preview {
    NavigationStack {
        CompatibilityResultsView()
    }
}
