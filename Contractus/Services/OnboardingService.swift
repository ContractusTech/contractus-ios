//
//  OnboardingService.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 29.08.2023.
//

import Foundation

protocol OnboardingService {
    func loadOnboarding() -> Onboadring?
    func needShowOnboarding() -> Bool
}

final class OnboardingServiceImpl: OnboardingService {
    private let decoder = JSONDecoder()
    
    func loadOnboarding() -> Onboadring? {
        if let path = Bundle.main.path(forResource: "Onboarding", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                if let onboarding = try? decoder.decode(Onboadring.self, from: data) {
                    return onboarding
                }
            } catch {
                debugPrint("Error")
            }
        }
        return nil
    }
    
    func needShowOnboarding() -> Bool {
        if let onboarding = loadOnboarding() {
            let id = FlagsStorage.shared.changelogId
            return !(FlagsStorage.shared.onboardingPresented && id >= onboarding.onboarding.changelog.id)
        } else {
            return false
        }
    }
}
