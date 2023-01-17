//
//  SignConfirmView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.01.2023.
//


import Foundation
import ContractusAPI
import SwiftUI
import QRCode


struct SignConfirmView: View {

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AnyViewModel<SignConfirmState, SignConfirmInput>

    var confirmAction: () -> Void
    var cancelAction: () -> Void

    init(account: CommonAccount, deal: Deal, confirmAction: @escaping () -> Void, cancelAction: @escaping () -> Void) {
        self._viewModel = .init(
            wrappedValue: .init(SignConfirmViewModel(
                account: account,
                deal: deal,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                transactionSignService: ServiceFactory.shared.makeTransactionSign())
            ))
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        ZStack (alignment: .bottomLeading) {
            ScrollView {

                VStack(alignment: .center) {
                    TopTextBlockView (
                        informationType: .warning,
                        headerText: "Confirm",
                        titleText: "Signature the deal",
                        subTitleText: self.description)
                    
                    VStack(alignment: .leading, spacing: 12) {

                        ForEach(viewModel.state.informationFields) { item in
                            HStack {
                                Text(item.title)
                                    .font(.body)
                                    .foregroundColor(R.color.textBase.color)
                                Spacer()
                                Text(item.value)
                                    .font(.body.weight(.medium))
                                    .foregroundColor(R.color.textBase.color)
                            }
                            Divider()
                        }
                    }
                    if
                        let tx = viewModel.state.transaction?.transaction
                    {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Transaction")
                                    .font(.body)
                                    .foregroundColor(R.color.textBase.color)
                                Spacer()
                            }

                            Text(tx)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                                .frame(height: 120)

                            CButton(title: R.string.localizable.commonCopy(), style: .secondary, size: .default, isLoading: false) {
                                ImpactGenerator.light()
                                UIPasteboard.general.string = tx
                            }
                        }
                    }


                }
                .padding(UIConstants.contentInset)
            }


            VStack(spacing: 12) {
                CButton(title: signButtonTitle, style: .warn, size: .large, isLoading: viewModel.state.state == .signing, isDisabled: viewModel.state.state == .loading) {
                    viewModel.trigger(.sign) {
                        
                    }
                }

                CButton(title: "Cancel", style: .secondary, size: .large, isLoading: false) {
                    presentationMode.wrappedValue.dismiss()
                    cancelAction()
                }
            }
            .padding(EdgeInsets(top: 20, leading: 22, bottom: 24, trailing: 22))
        }
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            viewModel.trigger(.loadActualTx)
        }

    }

    var signButtonTitle: String {
        if viewModel.state.state == .loading {
            return "Loading..."
        }
        return "Confirm and sign"

    }

    var description: String {
        ""
    }
}



struct SignConfirmView_Previews: PreviewProvider {

    static var previews: some View {
        SignConfirmView(account: Mock.account, deal: Mock.deal) {

        } cancelAction: {
            
        }


    }
}

