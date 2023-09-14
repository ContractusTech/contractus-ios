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
    var pages: [OnboardingPageModel] = []
    var selectedIndex: Int = 0
    var selectedPage: OnboardingPageModel? {
        pages[safe: selectedIndex]
    }

    var hasNext: Bool {
        pages[safe: (selectedIndex + 1)] != nil
    }

    var pagesCount: Int {
        pages.count
    }
}

final class OnboardingViewModel: ViewModel {

    enum ContentType {
        case onboarding
        case changelog
        case all
    }
    
    @Published private(set) var state: OnboardingState

    private var onboardingService: OnboardingService?
    private let contentType: ContentType

    init(
        contentType: ContentType,
        state: OnboardingState,
        onboardingService: OnboardingService?
    ) {
        self.contentType = contentType
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
        guard let onboardingService = onboardingService, let onboarding = onboardingService.content?.onboarding else { return }
        
        var onboardingPages = onboarding.pages
        var changelogPages: [OnboardingChangelogPage] = []

        if (contentType == .changelog || contentType == .all) && onboardingService.needShowChangelog() {
            changelogPages = onboarding.changelog.pages

            onboardingService.setShownChangelog()
        }

        if (contentType == .onboarding || contentType == .all) && onboardingService.needShowOnboarding() {
            state.pages = onboardingPages.map {
                OnboardingPageModel(
                    imageName: $0.imageName,
                    imageUrl: $0.imageUrl,
                    title: $0.title,
                    description: $0.description,
                    buttonType: onboardingPages.last == $0 && changelogPages.count == 0 ? .close : .next,
                    isChangelog: false
                )
            }

            onboardingService.setShowOnboarding()
        }

        state.pages.append(
            contentsOf: changelogPages.map {
                OnboardingPageModel(
                    imageName: $0.imageName,
                    imageUrl: $0.imageUrl,
                    title: $0.title,
                    description: $0.description,
                    buttonType: $0.needAccept ? .accept : (changelogPages.last == $0 ? .close : .next),
                    isChangelog: true
                )
            }
        )
    }
}
