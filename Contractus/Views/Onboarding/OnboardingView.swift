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
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .padding(.bottom, 20)
            .onChange(of: selectedPage) { newIndex in
                update(pageIndex: newIndex)
            }
            
            CButton(
                title: buttonTitle,
                style: .clear,
                size: .default,
                isLoading: false
            ) {
                withAnimation {
                    selectedPage = selectedPage + 1
                }

            }
            .padding(.bottom, 16)
        }
        .baseBackground()
    }

    var buttonTitle: String {
        switch viewModel.state.selectedPage?.buttonType {
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

    func update(pageIndex: Int) {
        switch viewModel.state.selectedPage?.buttonType {
        case .close:
            close()
        case .next:
            viewModel.trigger(.updateActivePage(pageIndex))
            if !viewModel.state.hasNext {
                close()
            }
        case .accept:
            viewModel.trigger(.accept)
            if !viewModel.state.hasNext {
                close()
            }
        case .none:
            return
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
