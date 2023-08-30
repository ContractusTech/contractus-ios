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
                ForEach(viewModel.state.onboardingPages, id: \.self) { page in
                    OnboardingPageView(page: page)
                        .tag(viewModel.state.onboardingPages.firstIndex(of: page)!)
                        .contentShape(Rectangle())
                        .gesture(page.buttonType == .accept ? DragGesture() : nil)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .padding(.bottom, 20)
            
            switch viewModel.state.onboardingPages[selectedPage].buttonType {
            case .close:
                CButton(
                    title: R.string.localizable.commonClose(),
                    style: .clear,
                    size: .default,
                    isLoading: false
                ) {
                    viewModel.trigger(.setPresented)
                    close()
                }
                .padding(.bottom, 16)
            case .skip:
                CButton(
                    title: R.string.localizable.commonSkip(),
                    style: .clear,
                    size: .default,
                    isLoading: false
                ) {
                    withAnimation{
                        selectedPage += 1
                    }
                }
                .padding(.bottom, 16)
            case .accept:
                CButton(
                    title: R.string.localizable.commonAccept(),
                    style: .clear,
                    size: .default,
                    isLoading: false
                ) {
                    if selectedPage == viewModel.state.pagesCount - 1 {
                        close()
                    } else {
                        withAnimation{
                            selectedPage += 1
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: AnyViewModel<OnboardingState, OnboardingInput>(OnboardingViewModel(
            state: OnboardingState(state: .none, errorState: .none),
            onboardingService: ServiceFactory.shared.makeOnboardingService()))
        ) {}
    }
}
