//
//  TransactionSignView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.01.2023.
//


import Foundation
import ContractusAPI
import SwiftUI

fileprivate enum Constants {
    static let successSignedImage = Image(systemName: "checkmark.circle.fill")

    static let successSignedShieldImage = Image(systemName: "checkmark.shield.fill")

    static let failTxImage = Image(systemName: "xmark.octagon.fill")
    static let shieldImage = Image(systemName: "exclamationmark.shield.fill")
    static let arrowDownImage = Image(systemName: "chevron.down")
    static let arrowUpImage = Image(systemName: "chevron.up")
    static let arrowRightImage = Image(systemName: "arrow.up.right")
    static let successCopyImage = Image(systemName: "checkmark")
    static let errorImage = Image(systemName: "xmark.circle.fill")
    static let copyImage = Image(systemName: "square.on.square")
    static let confirmTxImage = Image(systemName: "checkmark.seal.fill")
}

struct FieldCopyButton: View {
    let content: String
    @State private var copiedNotification: Bool = false

    var body: some View {
        Button {
            copiedNotification = true
            ImpactGenerator.light()
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
        case custom(icon: Image?, iconColor: Color?, callback: (() -> Void)?)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(R.color.textBase.color)
                if let titleDescription = titleDescription {
                    Text(titleDescription)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                }
            }

            Spacer()
            VStack(alignment: .trailing) {
                HStack(spacing: 6) {
                    Text(value)
                        .font(.callout)
                        .foregroundColor(valueTextColor)
                        .multilineTextAlignment(.trailing)
                    if isLoading {
                        ProgressView()
                    }
                    ForEach(buttons) { item in
                        switch item {
                        case .copy(let value):
                            FieldCopyButton(content: value)
                        case .custom(let icon, let iconColor, let callback):
                            Button {
                                callback?()
                            } label: {
                                icon?
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(iconColor ?? R.color.textBase.color)
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
    @State private var showTx: Bool = false

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
                                .lineSpacing(-1.1)
                                .multilineTextAlignment(.center)
                                .foregroundColor(R.color.textBase.color)

                            HStack(alignment: .center) {
                                Spacer()
                                Text(subtitle)
                                    .foregroundColor(R.color.secondaryText.color)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 32))
                        }

                    }
                    .padding(.bottom, 0)
                    .padding(.top, 24)
                    VStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.state.informationFields) { item in
                                TransactionDetailFieldView(
                                    title: item.title,
                                    value: item.value,
                                    isLoading: false,
                                    titleDescription: item.titleDescription,
                                    valueDescription: item.valueDescription)
                                if viewModel.state.informationFields.last == item {
                                    EmptyView()
                                } else {
                                    Divider().foregroundColor(R.color.baseSeparator.color.opacity(0.5)).padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
                                }

                            }
                        }
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                        if let tx = viewModel.state.transaction?.transaction {
                            VStack(alignment: .leading, spacing: 0) {
                                VStack(alignment: .leading) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(R.string.localizable.transactionSignFieldsTx())
                                                .font(.body)
                                                .foregroundColor(R.color.textBase.color)
                                            if viewModel.state.account.blockchain == .solana {
                                                Text(R.string.localizable.transactionSignFieldsBase64())
                                                    .font(.body)
                                                    .foregroundColor(R.color.secondaryText.color)
                                            }
                                            Spacer()

                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    EventService.shared.send(event: DefaultAnalyticsEvent.txDataViewTap)
                                                    showTx.toggle()
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
                                    if showTx {
                                        VStack(alignment: .leading) {
                                            Text(tx)
                                                .font(.footnote.monospaced())
                                                .foregroundColor(R.color.secondaryText.color)
                                        }
                                        HStack(spacing: 6) {
                                            CButton(title: R.string.localizable.commonCopy(), style: .secondary, size: .default, isLoading: false) {
                                                EventService.shared.send(event: DefaultAnalyticsEvent.txDataCopyTap)
                                                ImpactGenerator.light()
                                                UIPasteboard.general.string = tx
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                .padding()
                            }
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                            if let tx = viewModel.state.transaction, let signature = tx.signature, !signature.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    TransactionDetailFieldView(
                                        title: R.string.localizable.transactionSignFieldsSignature(),
                                        value: ContentMask.mask(from: signature),
                                        buttons: [
                                            .copy(value: signature),
                                            .custom(
                                                icon: Constants.arrowRightImage,
                                                iconColor: nil,
                                                callback: {
                                                    EventService.shared.send(event: DefaultAnalyticsEvent.txSignatureTap)
                                                    viewModel.trigger(.openExplorer)
                                                }),
                                        ]
                                    )
                                }
                                .background(R.color.secondaryBackground.color)
                                .cornerRadius(20)
                                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                            }
                        }
                    }
                    .padding()
                }
                .padding(UIConstants.contentInset)
                .padding(.bottom, 150)
            }
            VStack(spacing: 12) {
                signButton
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
        .onAppear {
            EventService.shared.send(event: DefaultAnalyticsEvent.txOpen)
        }
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
        let size: CGFloat = 28
        return ZStack {
            switch viewModel.transaction?.status {
            case .finished:
                RoundedRectangle(cornerRadius: 17)
                    .stroke(R.color.baseGreen.color, style: .init(lineWidth: 1))
                Constants.confirmTxImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(R.color.baseGreen.color)
            case .processing:
                RoundedRectangle(cornerRadius: 17)
                    .stroke(R.color.baseSeparator.color, style: .init(lineWidth: 1))
                ProgressView()
            case .new, .none:
                if viewModel.state.state == .signed {
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(R.color.baseGreen.color, style: .init(lineWidth: 1))
                    Constants.confirmTxImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .foregroundColor(R.color.baseGreen.color)
                } else {
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(R.color.baseSeparator.color, style: .init(lineWidth: 1))
                    Constants.confirmTxImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .foregroundColor(R.color.baseSeparator.color)
                }

            case .error:
                RoundedRectangle(cornerRadius: 17)
                    .stroke(R.color.labelBackgroundError.color, style: .init(lineWidth: 1))
                Constants.failTxImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(R.color.labelBackgroundError.color)
            }
        }
        .frame(width: size * 2, height: size * 2)
    }

    var signButton: some View {
        var icon: Image?
        let loading: Bool = viewModel.state.state == .signing || viewModel.state.transaction?.status == .processing
        let isDisable = viewModel.state.state == .loading || viewModel.state.state == .signing || viewModel.state.state == .signed || !viewModel.state.allowSign || viewModel.state.transaction?.status == .error
        var style: CButton.Style = .primary

        switch viewModel.state.transaction?.status {
        case .finished:
            icon = Constants.confirmTxImage
            style = .success
        case .error:
            icon = Constants.failTxImage
            style = .cancel
        case .processing:
            style = .primary
        default:
            if viewModel.state.state == .signed {
                icon = Constants.confirmTxImage
                style = .success
            }
        }
        return CButton(
            title: signButtonTitle,
            icon: icon,
            style: style,
            size: .large,
            isLoading: loading,
            isDisabled: isDisable
        ) {
            EventService.shared.send(event: DefaultAnalyticsEvent.txSignTap)
            viewModel.trigger(.sign) { }
        }
    }

    var signButtonTitle: String {
        switch viewModel.state.state {
        case .signed:
            switch viewModel.transaction?.status {
            case .processing:
                return R.string.localizable.transactionSignButtonsProcessing()
            case .finished:
                return R.string.localizable.transactionSignButtonsCompleted()
            case .error:
                return R.string.localizable.transactionSignButtonsError()
            default:
                return R.string.localizable.transactionSignButtonsSigned()
            }
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
        return R.string.localizable.transactionSignTitleConfirm()
    }

    var subtitle: String {
        if let errorMessage = viewModel.state.transaction?.errorDetail?.message {
            return errorMessage
        }
        var txType: TransactionType?
        switch viewModel.state.type  {
        case .byDeal(_, let type):
            txType = type
        case .byTransaction(let tx):
            txType = tx.type
        default: break
        }
        switch txType ?? viewModel.state.transaction?.type {
        case .dealInit:
            return R.string.localizable.transactionSignSubtitleUnsignedInitDeal()
        case .dealFinish:
            return R.string.localizable.transactionSignSubtitleFinishDeal()
        case .dealCancel:
            return R.string.localizable.transactionSignSubtitleCancelDeal()
        case .unwrapAllSOL, .unwrap:
            return R.string.localizable.transactionSignSubtitleUnwrap()
        case .wrapSOL, .wrap:
            return R.string.localizable.transactionSignSubtitleWrap()
        case .transfer:
            return R.string.localizable.transactionSignSubtitleTransfer()
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
        if !showTx {
            return Constants.arrowDownImage
        }
        return Constants.arrowUpImage
    }
}

struct SignConfirmView_Previews: PreviewProvider {

    static var previews: some View {
        TransactionSignView(account: Mock.account, type: .byDeal(Mock.deal, .dealFinish)) {

        } closeAction: { _ in
            
        }
        .previewDisplayName("By Deal")

        TransactionSignView(account: Mock.account, type: .byTransaction(Mock.wrapTransactionProcessing)) {

        } closeAction: { _ in

        }
        .previewDisplayName("By Transaction")

    }
}

