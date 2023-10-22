//
//  SendTokensView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.10.2023.
//

import SwiftUI

struct SendTokensView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>
    @State var nextStep: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    isActive: $nextStep,
                    destination: {
                        SelectRecipientView(
                            stepsState: viewModel.state.stepsState
                        )
                        .environmentObject(viewModel)
                    },
                    label: {
                        EmptyView()
                    }
                )

                TokenSelectView(viewModel: .init(TokenSelectViewModel(
                    allowHolderMode: true,
                    mode: .select,
                    tier: .holder,
                    selectedTokens: [],
                    disableUnselectTokens: [],
                    resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService())
                )) { result in
                    switch result {
                    case .single(let token):
                        viewModel.trigger(.setState({
                            var newStepsState = viewModel.state.stepsState
                            newStepsState.selectedToken = token
                            return newStepsState
                        }()))
                        nextStep.toggle()
                    case .close:
                        presentationMode.wrappedValue.dismiss()
                    case .none, .many:
                        break
                    }
                }
            }
        }
    }
}

#Preview {
    SendTokensView(
        viewModel: .init(SendTokensViewModel(accountAPIService: nil))
    )
}
