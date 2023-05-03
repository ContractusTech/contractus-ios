//
//  WrapTokenView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.02.2023.
//

import SwiftUI
import ContractusAPI

private enum Constants {
    static let arrowDownImage = Image(systemName: "arrow.right")
    static let swapImage = Image(systemName: "arrow.left.arrow.right")
    static let closeImage = Image(systemName: "xmark")
}
struct WrapTokenView: View {

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AnyViewModel<WrapTokenState, WrapTokenInput>

    @ObservedObject private var keyboard = KeyboardResponder(defaultHeight: UIConstants.contentInset.bottom)
    @State private var amount: String = ""
    @State private var showSign: Bool = false
    @State private var alertType: AlertType?

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 12) {
                        ZStack(alignment: .trailing) {
                            TextField(placeholder, text: $amount)
                                .padding(12)
                                .background(R.color.textFieldBackground.color)
                                .cornerRadius(20)
                                .font(.largeTitle.weight(.regular))
                                .multilineTextAlignment(.center)
                                .disabled(viewModel.operationType == .unwrap)
                                .opacity(viewModel.operationType == .unwrap ? 0.8 : 1.0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                                    )



                            HStack {
                                Button {
                                    amount = viewModel.from.formatted()
                                } label: {
                                    Text("All")
                                        .font(.footnote.weight(.regular))
                                        .padding(8)
                                        .background(R.color.thirdBackground.color)
                                        .foregroundColor(R.color.textBase.color)
                                        .cornerRadius(10)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(R.color.baseSeparator.color, lineWidth: 1)
                                        }
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                            .opacity(viewModel.allowAll ? 1.0 : 0)
                        }

                        HStack {
                            HStack {
                                Spacer()
                                VStack {
                                    Text(viewModel.from.token.code)
                                        .foregroundColor(R.color.textBase.color)
                                        .font(.title3.weight(.bold))

                                    Text(viewModel.from.formatted())
                                        .foregroundColor(R.color.secondaryText.color)
                                        .font(.footnote.weight(.regular))
                                }
                                Spacer()
                            }

                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .stroke(R.color.baseSeparator.color, lineWidth: 1)
                                        .frame(width: 28, height: 28)
                                    Constants.arrowDownImage.foregroundColor(R.color.secondaryText.color)
                                }
                                .frame(width: 28, height: 28)
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                VStack {
                                    Text(viewModel.to.token.code)
                                        .foregroundColor(R.color.textBase.color)
                                        .font(.title3.weight(.bold))
                                    Text(viewModel.to.formatted())
                                        .foregroundColor(R.color.secondaryText.color)
                                        .font(.footnote.weight(.regular))
                                }
                                Spacer()
                            }

                        }
                        .padding(16)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(R.color.baseSeparator.color, lineWidth: 1)
                        }

                        Button {

                            viewModel.trigger(.swap)
                            amount = viewModel.state.operationType == .unwrap ? viewModel.state.from.formatted() : ""
                        } label: {
                            HStack(spacing: 8) {
                                Constants.swapImage
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(R.color.textBase.color)
                                Text("Swap")
                                    .foregroundColor(R.color.textBase.color)
                            }
                        }
                    }
                }

                CButton(
                    title: buttonTitle,
                    style: .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .loading,
                    isDisabled: viewModel.disableAction
                ) {
                    viewModel.trigger(.send(amount))
                }
            }
            .onChange(of: amount, perform: { newValue in
                viewModel.trigger(.update(newValue))
            })
            .sheet(isPresented: $showSign) {
                if let type = viewModel.transactionSignType {
                    TransactionSignView(account: viewModel.state.account, type: type) {

                    } closeAction: { afterSign in
                        if afterSign {
                            presentationMode.wrappedValue.dismiss()
                        }

                    }.interactiveDismiss(canDismissSheet: false)
                } else {
                    EmptyView()
                }

            }
            .onChange(of: viewModel.transactionSignType) { type in
                showSign = type != nil
            }
            .onChange(of: viewModel.state.errorState) { errorState in
                switch errorState {
                case .error(let errorMessage):
                    self.alertType = .error(errorMessage)
                case .none:
                    self.alertType = nil
                }
            }
            .alert(item: $alertType, content: { type in
                switch type {
                case .error(let message):
                    return Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message), dismissButton: Alert.Button.default(Text("Ok"), action: {
                            viewModel.trigger(.hideError)
                        }))
                }
            })
            .padding(UIConstants.contentInset)
            .navigationTitle("(Un)Wrap token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .baseBackground()
        }

    }

    private var buttonTitle: String {
        switch viewModel.operationType {
        case .wrap:
            return "Wrap"
        case .unwrap:
            return "Unwrap all"
        }
    }

    private var placeholder: String {
        switch viewModel.operationType {
        case .wrap:
            return "Amount" //"Max \(viewModel.from.formatted())"
        case .unwrap:
            return "\(viewModel.from.formatted())"
        }
    }


}

struct WrapTokenView_Previews: PreviewProvider {
    static var previews: some View {
        WrapTokenView(viewModel: AnyViewModel<WrapTokenState, WrapTokenInput>(WrapTokenViewModel(
            state: .init(
                account: Mock.account, amountNativeToken: Amount("100000", token:  Mock.tokenSOL),
                amountWrapToken: Amount("0", token: Mock.tokenWSOL)), accountService: nil)))
    }
}
