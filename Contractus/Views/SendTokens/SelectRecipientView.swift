//
//  SelectRecipientView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.10.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
}

struct SelectRecipientView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>

    var stepsState: StepsState
    
    @State var publicKey: String = ""
    @State var nextStep: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(R.string.localizable.sendTokensRecipient())
                .font(.subheadline)
                .textCase(.uppercase)
                .foregroundColor(R.color.secondaryText.color)

            TextFieldView(
                placeholder: R.string.localizable.commonPublicKey(), 
                blockchain: .solana,
                value: stepsState.recipient,
                changeValue: { newValue in
                    publicKey = newValue
                }, onQRTap: {
                    EventService.shared.send(event: DefaultAnalyticsEvent.dealContractorQrscannerTap)
                }
            )

            Spacer()
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    SelectAmountView(
                        stepsState: viewModel.state.stepsState
                    )
                    .environmentObject(viewModel)
                },
                label: {
                    EmptyView()
                }
            )
            CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, action: {
                viewModel.trigger(.setState({
                    var newStepsState = viewModel.state.stepsState
                    newStepsState.recipient = publicKey
                    return newStepsState
                }()))
                nextStep.toggle()
            })
        }
        .onAppear {
            publicKey = stepsState.recipient
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .baseBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Constants.backImage
                    .resizable()
                    .frame(width: 12, height: 21)
                    .foregroundColor(R.color.textBase.color)
            }
        )
//        .onChange(of: viewModel.state.currentStep) { newValue in
//            self.currentStep = newValue
//        }
    }

    var title: String {
        return R.string.localizable.sendTokensSendTitle(stepsState.selectedToken?.code ?? "")
    }
}

#Preview {
    SelectRecipientView(
        stepsState: StepsState()
    )
}
