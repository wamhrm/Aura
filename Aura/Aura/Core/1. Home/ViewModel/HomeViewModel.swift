//
//  HomeViewModel.swift
//  Aura
//
//  Created by ddorsat on 31.03.2026.
//

import Foundation
import SwiftUI
import Combine

enum HomeRoutes: Hashable {
    case tests
    case testDetails(TestType)
    case testResults
    case horoscopeDetails
    case addProfileInfo
}

final class HomeViewModel: ObservableObject {
    @Published var homeRoutes: [HomeRoutes] = []
    @Published var userSex: AddProfileInfoCellType.Gender?
    @Published var socialType: AddProfileInfoCellType.SocialType?
    @Published var conflictStyle: AddProfileInfoCellType.ConflictStyle?
    @Published var emotionalCore: AddProfileInfoCellType.EmotionalCore?
    @Published var decisionStyle: AddProfileInfoCellType.DecisionStyle?
    @Published var coreFocus: AddProfileInfoCellType.CoreRelationshipFocus?
    
    @Published var selectedTests: [TestType] = []
    @Published var showMinTestsAlert = false
    
    private let minSelectedTests = 2
    
    init() {
        minimumSelectedTests()
    }
    
    func selectTest(_ test: TestType) {
        if !selectedTests.contains(test) {
            selectedTests.append(test)
        }
    }
    
    func toggleTestSelection(_ test: TestType) {
        if let index = selectedTests.firstIndex(of: test) {
            guard selectedTests.count > minSelectedTests else {
                showMinTestsAlert = true
                return
            }
            
            selectedTests.remove(at: index)
        } else {
            selectedTests.append(test)
        }
    }
    
    private func minimumSelectedTests() {
        if selectedTests.count < minSelectedTests {
            selectedTests = Array(TestType.allCases.prefix(minSelectedTests))
        }
    }
}
