//
//  OnboardingViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 29.08.2023.
//

import Foundation

enum OnboardingInput {
    case accept, updateActivePage(Int)
}

enum OnboardingPageButton {
    case next, close, accept
}

struct OnboardingPageModel: Hashable {
    let imageName: String?
    let imageUrl: String?
    let title: String?
    let description: String?
    let buttonType: OnboardingPageButton
    let isChangelog: Bool
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
    var onboardingPages: [OnboardingPageModel] = []
    var selectedIndex: Int = 0
    var selectedPage: OnboardingPageModel? {
        onboardingPages[safe: selectedIndex]
    }

    var hasNext: Bool {
        onboardingPages[safe: (selectedIndex + 1)] != nil
    }

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
        case .updateActivePage(let index):
            state.selectedIndex = index
        case .accept:
            state.errorState = nil
        }
    }
    
    func loadOnboarding() {
        guard let onboarding = onboardingService?.content?.onboarding else { return }
        
        var onboardingPages = onboarding.pages
        var changelogPages: [OnboardingChangelogPage] = []
        if onboardingService?.needShowChangelog() ?? false {
            changelogPages = onboarding.changelog.pages

            FlagsStorage.shared.changelogId = onboarding.changelog.id
        }

        if !FlagsStorage.shared.onboardingPresented {
            state.onboardingPages = onboardingPages.map {
                OnboardingPageModel(
                    imageName: $0.imageName,
                    imageUrl: $0.imageUrl,
                    title: $0.title,
                    description: $0.description,
                    buttonType: onboardingPages.last == $0 && changelogPages.count == 0 ? .close : .next,
                    isChangelog: false
                )
            }

            FlagsStorage.shared.onboardingPresented = true
        }

        state.onboardingPages.append(
            contentsOf: changelogPages.map {
                OnboardingPageModel(
                    imageName: $0.imageName,
                    imageUrl: $0.imageUrl,
                    title: $0.title,
                    description: $0.description,
                    buttonType: $0.needAccept ? .accept : changelogPages.last == $0 ? .close : .next,
                    isChangelog: true
                )
            }
        )
    }
}
