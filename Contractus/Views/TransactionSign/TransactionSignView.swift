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
    static let successSignedShieldImage = Image(systemName: "checkmark.shield.fill")
    static let shieldImage = Image(systemName: "exclamationmark.shield.fill")
    static let arrowDownImage = Image(systemName: "chevron.down")
    static let arrowUpImage = Image(systemName: "chevron.up")
    static let arrowRightImage = Image(systemName: "arrow.up.right")
    static let successCopyImage = Image(systemName: "checkmark")
    static let errorImage = Image(systemName: "xmark.circle.fill")
    static let copyImage = Image(systemName: "square.on.square")
}

fileprivate let HEIGHT_TX_VIEW: CGFloat = 120

struct FieldCopyButton: View {
    let content: String
    @State private var copiedNotification: Bool = false

    var body: some View {
        Button {
            copiedNotification = true
            ImpactGenerator.soft()
            UIPasteboard.general.string = content
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                copiedNotification = false
            })
        } label: {
            HStack {
                if copiedNotification {
                    Constants.successCopyImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(R.color.baseGreen.color)
                } else {
                    Constants.copyImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(R.color.textBase.color)
                }
            }
            .frame(width: 24, height: 24)
        }
    }
}

struct TransactionDetailFieldView: View {

    enum FieldButton: Identifiable {
        var id: String { "\(self)" }
        case copy(value: String)
        case custom(icon: Image?, callback: (() -> Void)?)
    }

    let title: String
    let value: String

    var isLoading: Bool = false
    var titleDescription: String? = nil
    var valueDescription: String? = nil
    var valueTextColor: Color = R.color.secondaryText.color
    var buttons: [FieldButton] = []

    var body: some View {
        HStack {
            VStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(R.color.textBase.color)
                if let titleDescription = titleDescription {
                    Text(titleDescription)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                }
            }

            Spacer()
            VStack {
                HStack(spacing: 8) {
                    Text(value)
                        .font(.body)
                        .foregroundColor(valueTextColor)
                    if isLoading {
                        ProgressView()
                    }
                    ForEach(buttons) { item in
                        switch item {
                        case .copy(let value):
                            FieldCopyButton(content: value)
                        case .custom(let icon, let callback):
                            Button {
                                callback?()
                            } label: {
                                icon?
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(R.color.textBase.color)
                            }
                            .frame(width: 24, height: 24)
                        }
                    }
                }
                if let valueDescription = valueDescription {
                    Text(valueDescription)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                }
            }
        }.padding()
    }
}

struct TransactionSignView: View {

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AnyViewModel<TransactionSignState, TransactionSignInput>

    var signedAction: () -> Void
    var closeAction: (Bool) -> Void

    @State private var alertType: AlertType?
    @State private var heightTransaction: CGFloat? = HEIGHT_TX_VIEW

    init(account: CommonAccount, type: TransactionSignType, signedAction: @escaping () -> Void, closeAction: @escaping (Bool) -> Void) {
        self._viewModel = .init(
            wrappedValue: .init(TransactionSignViewModel(
                account: account,
                type: type,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                accountService: try? APIServiceFactory.shared.makeAccountService(), transactionSignService: ServiceFactory.shared.makeTransactionSign(),
            transactionsService: try? APIServiceFactory.shared.makeTransactionsService())
            ))
        self.signedAction = signedAction
        self.closeAction = closeAction
    }

    var body: some View {
        ZStack (alignment: .bottomLeading) {
            ScrollView {

                VStack(alignment: .center, spacing: 6) {
                    VStack {
                        imageStatusView
                        VStack(spacing: 12) {
                            Text(title)
                                .font(.largeTitle.weight(.medium))
                                .tracking(-1.1)
                                .multilineTextAlignment(.center)
                                .foregroundColor(R.color.textBase.color)
                            HStack {
                                Spacer()
                                Text(subtitle)
                                    .foregroundColor(R.color.secondaryText.color)
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
                            TransactionDetailFieldView(
                                title: item.title,
                                value: item.value,
                                isLoading: false,
                                titleDescription: item.titleDescription,
                                valueDescription: item.valueDescription)
                        }
                    }
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    if let tx = viewModel.state.transaction?.transaction {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(R.string.localizable.transactionSignFieldsTx())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                        Text(R.string.localizable.transactionSignFieldsBase64())
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
                                }
                            }
                            .padding()
                        }
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    }
                    if let tx = viewModel.state.transaction, let signature = tx.signature, !signature.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            TransactionDetailFieldView(
                                title: R.string.localizable.transactionSignFieldsSignature(),
                                value: ContentMask.mask(from: signature),
                                buttons: [
                                    .copy(value: signature),
                                    .custom(
                                        icon: Constants.arrowRightImage,
                                        callback: {
                                            viewModel.trigger(.openExplorer)
                                        }),
                                ]
                            )
                        }
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    }
                }
                .padding(UIConstants.contentInset)
                .padding(.bottom, 150)
            }
            VStack(spacing: 12) {
                CButton(
                    title: signButtonTitle,
                    icon: viewModel.state.state == .signed ? Constants.successSignedImage : nil,
                    style: .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .signing,
                    isDisabled: viewModel.state.state == .loading || viewModel.state.state == .signing || viewModel.state.state == .signed || !viewModel.state.allowSign) {
                    viewModel.trigger(.sign) {
                        
                    }
                }

                CButton(title: cancelButtonTitle, style: .secondary, size: .large, isLoading: false, isDisabled: viewModel.state.state == .loading || viewModel.state.state == .signing) {
                    presentationMode.wrappedValue.dismiss()
                    closeAction(viewModel.state.transaction?.status != .new)
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
                    message: Text(message), dismissButton: Alert.Button.default(Text(R.string.localizable.commonOk()), action: {
                        viewModel.trigger(.hideError)
                    }))
            }
        })

        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
    }

    var imageStatusView: some View {
        ZStack {
            switch viewModel.transaction?.status {
            case .finished:
                RoundedRectangle(cornerRadius: 17)
                    .fill(R.color.baseGreen.color)
                Constants.successSignedShieldImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)
                    .foregroundColor(R.color.secondaryBackground.color)
            case .processing:
                RoundedRectangle(cornerRadius: 17)
                    .fill(R.color.secondaryBackground.color)
                ProgressView()
            case .new, .none:
                RoundedRectangle(cornerRadius: 17)
                    .fill(R.color.secondaryBackground.color)
                Constants.shieldImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)
                    .foregroundColor(R.color.textBase.color)
            case .error:
                RoundedRectangle(cornerRadius: 17)
                    .fill(R.color.labelBackgroundError.color)
                Constants.errorImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)
                    .foregroundColor(R.color.white.color)
            }
        }
        .frame(width: 48, height: 48)
    }

    var signButtonTitle: String {
        switch viewModel.state.state {
        case .signed:
            return R.string.localizable.transactionSignButtonsSigned()
        case .signing:
            return R.string.localizable.transactionSignButtonsSigning()
        case .loading:
            return R.string.localizable.transactionSignButtonsLoading()
        case .loaded:
            return R.string.localizable.transactionSignButtonsSign()
        }
    }

    var cancelButtonTitle: String {
        if viewModel.state.state == .signed {
            return R.string.localizable.commonClose()
        }
        return R.string.localizable.commonCancel()
    }

    var title: String {
        switch viewModel.transaction?.status {
        case .finished:
            return R.string.localizable.transactionSignStatusesDone()
        case .processing:
            return R.string.localizable.transactionSignStatusesProcessing()
        case .error:
            return R.string.localizable.transactionSignStatusesError()
        case .new, .none:
            return R.string.localizable.transactionSignTitleNeedSign()
        }
    }

    var subtitle: String {
        switch viewModel.transaction?.status {
        case .processing:
            return R.string.localizable.transactionSignSubtitleProcessing()
        case .error:
            return "Try again"
        case .new:
            switch viewModel.state.transaction?.type {
            case .dealInit:
                return R.string.localizable.transactionSignSubtitleUnsignedInitDeal()
            default:
                return R.string.localizable.transactionSignSubtitleCommon()
            }
        case .finished:
            return "Transaction completed successfully"
        case .none:
            return ""
        }

    }

    var statusTextColor: Color {
        switch viewModel.state.transaction?.status {
        case .processing:
            return R.color.secondaryText.color
        case .finished:
            return R.color.baseGreen.color
        case .new, .none:
            return R.color.textBase.color
        case .error:
            return R.color.labelTextAttention.color
        }
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
        TransactionSignView(account: Mock.account, type: .byDeal(Mock.deal, .dealFinish)) {

        } closeAction: { _ in
            
        }.previewDisplayName("By Deal")

        TransactionSignView(account: Mock.account, type: .byTransaction(Mock.wrapTransactionProcessing)) {

        } closeAction: { _ in

        }.previewDisplayName("By Transaction")

    }
}

