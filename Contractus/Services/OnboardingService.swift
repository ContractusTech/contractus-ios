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
    func changelogId() -> Int
    func setShowOnboarding()
    func setShownChangelog()
}

final class OnboardingServiceImpl: OnboardingService {

    static let shared: OnboardingService = OnboardingServiceImpl()

    private let decoder = JSONDecoder()

    var content: Onboadring?

    init() {
        content = load()
    }

    func setShowOnboarding() {
        FlagsStorage.shared.onboardingPresented = true
    }

    func setShownChangelog() {
        guard let content = content else { return }

        FlagsStorage.shared.changelogId = content.onboarding.changelog.id
    }
    
    func needShowOnboarding() -> Bool {
        guard let content = content else { return false }

        return !FlagsStorage.shared.onboardingPresented
    }

    func needShowChangelog() -> Bool {
        guard let content = content else { return false }

        let id = FlagsStorage.shared.changelogId
        return id < content.onboarding.changelog.id
    }
    
    func changelogId() -> Int {
        guard let content = content else { return 0 }
        return content.onboarding.changelog.id
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
