//
//  OnboardingView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 23.08.2023.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: AnyViewModel<OnboardingState, OnboardingInput>
    @State private var selectedPage = 0
    
    var close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(viewModel.state.pages, id: \.id) { page in
                    OnboardingPageView(page: page)
                        .tag(viewModel.state.pages.firstIndex(of: page)!)
                        .contentShape(Rectangle())
                        .gesture(page.buttonType == .accept ? DragGesture() : nil)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .padding(.bottom, 20)
            
            CButton(
                title: buttonTitle(for: viewModel.state.pages[safe: selectedPage]),
                style: viewModel.state.pages[safe: selectedPage]?.buttonType == .accept ? .primary : .clear,
                size: .default,
                isLoading: false
            ) {
                action()

            }
            .padding(.bottom, 16)
        }
        .baseBackground()
    }

    var hasNext: Bool {
        viewModel.state.pages[safe: selectedPage + 1] != nil
    }

    func buttonTitle(for page: OnboardingPageModel?) -> String {
        switch page?.buttonType {
        case .close:
            return R.string.localizable.commonClose()
        case .next:
            return  R.string.localizable.commonNext()
        case .accept:
            return R.string.localizable.commonAccept()
        case .none:
            return ""
        }
    }

    func action() {
        guard let buttonType = viewModel.state.pages[safe: selectedPage]?.buttonType else { return }
        switch buttonType {
        case .close:
            close()
        case .next:
            if hasNext {
                withAnimation {
                    selectedPage += 1
                }
            } else {
                close()
            }
        case .accept:
            viewModel.trigger(.accept)
            if hasNext {
                withAnimation {
                    selectedPage += 1
                }
            } else {
                close()
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: AnyViewModel<OnboardingState, OnboardingInput>(OnboardingViewModel(
            contentType: .all,
            state: OnboardingState(state: .none, errorState: .none),
            onboardingService: ServiceFactory.shared.makeOnboardingService()))
        ) {}
    }
}
