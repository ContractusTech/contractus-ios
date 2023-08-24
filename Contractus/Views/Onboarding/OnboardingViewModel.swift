//
//  OnboardingViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 29.08.2023.
//

import Foundation

enum OnboardingInput {
    case accept, setPresented
}

enum OnboardingPageButton {
    case skip, close, accept
}

struct OnboardingViewPage: Hashable {
    let imageName: String?
    let imageUrl: String?
    let title: String?
    let description: String?
    let buttonType: OnboardingPageButton
}

struct OnboardingState {
    
    enum State: Equatable {
        case none
    }
    
    enum ErrorState: Equatable {
        case error(String)
    }

    var state: State = .none

    var errorState: ErrorState?
    var onboardingPages: [OnboardingViewPage] = []

    var pagesCount: Int {
        onboardingPages.count
    }
}

final class OnboardingViewModel: ViewModel {
    
    @Published private(set) var state: OnboardingState

    private var onboardingService: OnboardingService?

    init(
        state: OnboardingState,
        onboardingService: OnboardingService?
    ) {
        self.state = state
        self.onboardingService = onboardingService
        
        loadOnboarding()
    }
    
    func trigger(_ input: OnboardingInput, after: AfterTrigger? = nil) {
        switch input {
        case .accept:
            state.errorState = nil
        case .setPresented:
            FlagsStorage.shared.onboardingPresented = true
        }
    }
    
    func loadOnboarding() {
        if let onboarding = onboardingService?.loadOnboarding()?.onboarding {
            var onboardingPages = onboarding.pages
            var changelogPages: [OnboardingChangelogPage] = []
            if onboarding.changelog.id > FlagsStorage.shared.changelogId {
                changelogPages = onboarding.changelog.pages
            }

            if !FlagsStorage.shared.onboardingPresented {
                state.onboardingPages = onboardingPages.map {
                    OnboardingViewPage(
                        imageName: $0.imageName,
                        imageUrl: $0.imageUrl,
                        title: $0.title,
                        description: $0.description,
                        buttonType: onboardingPages.last == $0 && changelogPages.count == 0 ? .close : .skip
                    )
                }
            }
            state.onboardingPages.append(
                contentsOf: changelogPages.map {
                    OnboardingViewPage(
                        imageName: $0.imageName,
                        imageUrl: $0.imageUrl,
                        title: $0.title,
                        description: $0.description,
                        buttonType: $0.needAccept ? .accept : changelogPages.last == $0 ? .close : .skip
                    )
                }
            )
        }
    }
}
