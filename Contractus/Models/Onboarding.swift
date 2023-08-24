//
//  Onboarding.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 29.08.2023.
//

import Foundation

struct OnboardingPage: Codable, Hashable {
    let imageName: String?
    let imageUrl: String?
    let title: String?
    let description: String?
}

struct OnboardingChangelogPage: Codable, Hashable {
    let imageName: String?
    let imageUrl: String?
    let title: String?
    let description: String?
    let needAccept: Bool
}

struct OnboardingChangelog: Codable, Hashable {
    let id: Int
    let pages: [OnboardingChangelogPage]
}

struct OnboadringContent: Codable, Hashable {
    let pages: [OnboardingPage]
    let changelog: OnboardingChangelog
}

struct Onboadring: Codable, Hashable {
    let onboarding: OnboadringContent
 }
