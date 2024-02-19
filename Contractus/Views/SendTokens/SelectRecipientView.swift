import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
}

struct SelectRecipientView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>

    @State var publicKey: String = ""
    @State var nextStep: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(R.string.localizable.sendTokensRecipient())
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .foregroundColor(R.color.secondaryText.color)

            TextFieldView(
                placeholder: placeholder,
                blockchain: viewModel.state.account.blockchain,
                value: viewModel.state.recipient,
                changeValue: { newValue in
                    publicKey = newValue
                    viewModel.trigger(.validateRecipient(newValue))
                }, onQRTap: {
                    EventService.shared.send(event: DefaultAnalyticsEvent.dealContractorQrscannerTap)
                }
            )
            if !publicKey.isEmpty && !viewModel.isValidImportedPrivateKey {
                Text(R.string.localizable.sendTokensInvalidRecipient())
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(R.color.labelBackgroundError.color)
                    .padding(.top, 8)
            }
            Spacer()
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    SelectAmountView(
                        amountValue: viewModel.state.amount
                    )
                    .environmentObject(viewModel)
                },
                label: {
                    EmptyView()
                }
            )
            CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.isValidImportedPrivateKey) {
                viewModel.trigger(.setRecipient(publicKey))
                nextStep.toggle()
            }
        }
        .onAppear {
            publicKey = viewModel.state.recipient
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
    }

    var title: String {
        return R.string.localizable.sendTokensSendTitle(viewModel.state.selectedToken?.code ?? "")
    }

    var placeholder: String {
        if viewModel.state.account.blockchain == .solana {
            return R.string.localizable.commonPublicKey()
        }
        return R.string.localizable.commonAddress()
    }
}

#Preview {
    SelectRecipientView()
}
