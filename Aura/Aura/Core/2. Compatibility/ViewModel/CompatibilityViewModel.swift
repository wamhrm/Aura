//
//  CompatibilityViewModel.swift
//  Aura
//
//  Created by ddorsat on 08.05.2026.
//

import Foundation
import Combine

enum CompatibilityRoutes: Hashable {
    case testDetails(CompatibilityTestType)
}

final class CompatibilityViewModel: ObservableObject {
    @Published var compatibilityRoutes: [CompatibilityRoutes] = []
    @Published var partnerName = ""
    @Published var exactDateOfBirth = true
    @Published var partnerDateOfBirth = ""
    @Published var partnerTimeOfBirth = ""
    @Published var partnerAge = ""
    @Published var partnerGender = ""
    @Published var selectedTests: [CompatibilityTestType] = []
    @Published var showMinTestsAlert = false
    
    private let minSelectedTests = 2
    
    init() {
        minimumSelectedTests()
    }
    
    var disableAnalyzeButton: Bool {
        return !partnerName.isEmpty && !partnerGender.isEmpty
    }
    
    func toggleTestSelection(_ test: CompatibilityTestType) {
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
    
    func minimumSelectedTests() {
        if selectedTests.count < minSelectedTests {
            selectedTests = Array(CompatibilityTestType.allCases.prefix(minSelectedTests))
        }
    }
}
