//
//  TransactionSignView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.01.2023.
//


import Foundation
import ContractusAPI
import SwiftUI
import QRCode

private enum Constants {
    static let successSignedImage = Image(systemName: "checkmark.circle.fill")
    static let shieldImage = Image(systemName: "exclamationmark.shield.fill")
    static let arrowDownImage = Image(systemName: "chevron.down")
    static let arrowUpImage = Image(systemName: "chevron.up")

}

fileprivate let HEIGHT_TX_VIEW: CGFloat = 120

struct TransactionSignView: View {

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AnyViewModel<TransactionSignState, TransactionSignInput>

    var signedAction: () -> Void
    var cancelAction: () -> Void

    @State private var alertType: AlertType?
    @State private var heightTransaction: CGFloat? = HEIGHT_TX_VIEW

    init(account: CommonAccount, type: TransactionSignType, signedAction: @escaping () -> Void, cancelAction: @escaping () -> Void) {
        self._viewModel = .init(
            wrappedValue: .init(TransactionSignViewModel(
                account: account,
                type: type,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                accountService: try? APIServiceFactory.shared.makeAccountService(), transactionSignService: ServiceFactory.shared.makeTransactionSign())
            ))
        self.signedAction = signedAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        ZStack (alignment: .bottomLeading) {
            ScrollView {

                VStack(alignment: .center, spacing: 8) {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 17)
                                .fill(R.color.accentColor.color)
                            Constants.shieldImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 21, height: 21)

                                .foregroundColor(R.color.secondaryBackground.color)
                        }
                        .frame(width: 48, height: 48)

                        VStack(spacing: 12) {
                            Text(title)
                                .font(.largeTitle.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(R.color.textBase.color)
                            HStack {
                                Spacer()
                                Text(subtitle)
                                    .foregroundColor(R.color.textBase.color)
                                    .font(.callout)
                                    .multilineTextAlignment(.center)
                                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                Spacer()
                            }
                        }

                    }
                    .padding(.bottom, 24)
                    .padding(.top, 24)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.state.informationFields) { item in
                            HStack {
                                VStack {
                                    Text(item.title)
                                        .font(.body)
                                        .foregroundColor(R.color.textBase.color)
                                    if let titleDescription = item.titleDescription {
                                        Text(titleDescription)
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                }

                                Spacer()
                                VStack {
                                    Text(item.value)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(R.color.textBase.color)
                                    if let valueDescription = item.valueDescription {
                                        Text(valueDescription)
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                }

                            }
                            .padding()

                        }
                    }
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    if let tx = viewModel.state.transaction?.transaction {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Transaction")
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                        Text("Base 64")
                                            .font(.body)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                }

                                Spacer()
                                VStack(alignment: .leading) {
                                    Text(tx)
                                        .font(.footnote.monospaced())
                                        .foregroundColor(R.color.secondaryText.color)
                                        .frame(height: heightTransaction)
                                }
                                HStack(spacing: 6) {
                                    CButton(title: R.string.localizable.commonCopy(), style: .secondary, size: .default, isLoading: false) {
                                        ImpactGenerator.light()
                                        UIPasteboard.general.string = tx
                                    }
                                    if viewModel.state.transaction?.signature != nil {
                                        CButton(title: "View in solscan", style: .secondary, size: .default, isLoading: false) {

                                        }
                                    }
                                    Spacer()
                                    Button {
                                        if heightTransaction == HEIGHT_TX_VIEW {
                                            heightTransaction = nil
                                        } else {
                                            heightTransaction = HEIGHT_TX_VIEW
                                        }
                                    } label: {
                                        transactionButtonImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(R.color.textBase.color)

                                    }

//                                    CButton(title: "", icon: transactionButtonImage, style: .secondary, size: .default, isLoading: false) {
//
//
//
//                                    }

                                }


                            }
                            .padding()
                        }
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                    }
                }
                .padding(UIConstants.contentInset)
                .padding(.bottom, 150)
            }
            VStack(spacing: 12) {
                CButton(
                    title: signButtonTitle,
                    icon: viewModel.state.state == .signed ? Constants.successSignedImage : nil,
                    style: viewModel.state.state == .signed ? .success : .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .signing,
                    isDisabled: viewModel.state.state == .loading || viewModel.state.state == .signing || viewModel.state.state == .signed || !viewModel.state.allowSign) {
                    viewModel.trigger(.sign) {
                        
                    }
                }

                CButton(title: cancelButtonTitle, style: .secondary, size: .large, isLoading: false, isDisabled: viewModel.state.state == .loading || viewModel.state.state == .signing) {
                    presentationMode.wrappedValue.dismiss()
                    cancelAction()
                }
            }
            .padding(EdgeInsets(top: 20, leading: 8, bottom: 24, trailing: 8))
            .baseBackground()
        }
        .onChange(of: viewModel.state.errorState) { errorState in
            switch errorState {
            case .error(let errorMessage):
                self.alertType = .error(errorMessage)
            case .none:
                self.alertType = nil
            }
        }
        .onChange(of: viewModel.state.state, perform: { newState in
            switch newState {
            case .signed:
                signedAction()
            case .signing, .loaded, .loading:
                break
            }
        })
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

        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
    }

    var signButtonTitle: String {
        switch viewModel.state.state {
        case .signed:
            return "Signed"
        case .signing, .loading:
            return "Signing..."
        case .loaded:
            return "Confirm and sign"
        }
    }

    var cancelButtonTitle: String {
        if viewModel.state.state == .signed {
            return "Close"
        }
        return "Cancel"
    }

    var title: String {
        return "Sign transaction"
    }

    var subtitle: String {
        return "After the transaction is signed by all parties, the client's funds will be frozen for the duration of the work."
    }

    var transactionButtonImage: Image {
        if heightTransaction == HEIGHT_TX_VIEW {
            return Constants.arrowDownImage
        }
        return Constants.arrowUpImage
    }
}



struct SignConfirmView_Previews: PreviewProvider {

    static var previews: some View {
        TransactionSignView(account: Mock.account, type: .byDeal(Mock.deal)) {

        } cancelAction: {
            
        }.previewDisplayName("By Deal")

        TransactionSignView(account: Mock.account, type: .byTransaction(Mock.wrapTransaction)) {

        } cancelAction: {

        }.previewDisplayName("By Transaction")

    }
}

