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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        if let needAccept = try container.decodeIfPresent(Bool.self, forKey: .needAccept) {
            self.needAccept = needAccept
        } else {
            self.needAccept = false
        }
    }
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
