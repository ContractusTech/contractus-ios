//
//  OnboardingService.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 29.08.2023.
//

import Foundation

protocol OnboardingService {
    var content: Onboadring? { get }
    func needShowOnboarding() -> Bool
    func needShowChangelog() -> Bool
    func setShowOnboarding()
    func setShownChangelog()
    func needShow() -> Bool
}

final class OnboardingServiceImpl: OnboardingService {

    private let decoder = JSONDecoder()

    var content: Onboadring?

    init() {
        content = load()
    }

    func needShow() -> Bool {
        needShowChangelog() || needShowOnboarding()
    }

    func setShowOnboarding() {
        FlagsStorage.shared.onboardingPresented = true
    }

    func setShownChangelog() {
        guard let content = content else { return }

        FlagsStorage.shared.changelogId = content.onboarding.changelog.id
    }
    
    func needShowOnboarding() -> Bool {
        // TODO: - Remove, need for test
        return true
        
        guard let content = content else { return false }

        return !FlagsStorage.shared.onboardingPresented
    }

    func needShowChangelog() -> Bool {
        // TODO: - Remove, need for test
        return true

        guard let content = content else { return false }

        let id = FlagsStorage.shared.changelogId
        return id < content.onboarding.changelog.id
    }

    private func load() -> Onboadring? {
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
}
