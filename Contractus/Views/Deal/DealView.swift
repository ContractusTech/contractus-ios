//
//  DealView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.08.2022.
//

import Foundation
import SwiftUI
import ContractusAPI
import ResizableSheet

fileprivate enum Constants {
    static let dotsImage = Image(systemName: "ellipsis")
    static let arrowUpImage = Image(systemName: "arrow.up")
    static let arrowDownImage = Image(systemName: "arrow.down")
}

struct DealView: View {

    enum AlertType {
        case error(String)
    }

    enum ActiveSheetType {
        case editContent(String?)
        case editContractor(String?)
        case editChecker(String?)
        case changeAmount
        case importSharedKey
    }

    enum FileUploaderType {
        case contractFile, resultFile
    }

    @StateObject var viewModel: AnyViewModel<DealState, DealInput>

    @State var actionSheetType: ActiveSheetType?
    @State var alertType: AlertType?
    @State var isActiveContractorOptions: Bool = false
    @State var uploaderState: ResizableSheetState = .hidden

    var body: some View {
        ScrollView {
            VStack {
                if !viewModel.state.canEdit {
                    HStack {
                        VStack {
                            Text("Not found shared key!")
                                .font(.body)
                        }
                        Button {
                            actionSheetType = .importSharedKey
                        } label: {
                            Text(R.string.localizable.commonAdd())
                        }
                        .buttonStyle(PrimaryMediumButton())


                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(R.color.yellow.color)
                    .cornerRadius(20)
                }
                VStack {
                    ZStack(alignment: .bottomLeading) {
                        VStack {
                            VStack(alignment: .leading) {
                                // MARK: - Client
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Client")
                                            .font(.footnote.weight(.semibold))
                                            .textCase(.uppercase)
                                            .foregroundColor(R.color.secondaryText.color)
                                        if viewModel.isOwnerDeal {
                                            Label(text: R.string.localizable.commonYou(), type: .primary)
                                        }

                                    }
                                    Text(KeyFormatter.format(from: viewModel.state.deal.ownerPublicKey))
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                                Divider().foregroundColor(R.color.baseSeparator.color).padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))

                                // MARK: - Amount
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Amount of contract")
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }
                                        HStack(alignment: .lastTextBaseline) {
                                            Text(viewModel.state.deal.amountFormatted)
                                                .font(.largeTitle)
                                            Text(viewModel.state.deal.currency.code).font(.footnote.weight(.semibold))
                                                .foregroundColor(R.color.secondaryText.color)
                                        }

                                    }
                                    Spacer()
                                    if viewModel.state.canEdit {
                                        Button {
                                            actionSheetType = .changeAmount
                                        } label: {
                                            Text(R.string.localizable.commonEdit())
                                                .foregroundColor(R.color.textBase.color)
                                        }
                                        .buttonStyle(SecondaryMediumButton())
                                        .disabled(!viewModel.state.isOwnerDeal)
                                    }

                                }
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            }
                            .padding(16)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)

                            // MARK: - Executor
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Executor")
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)
                                            if viewModel.state.isYouExecutor {
                                                Label(text: R.string.localizable.commonYou(), type: .primary)
                                            }

                                        }
                                        if viewModel.state.executorPublicKey.isEmpty {
                                            Text("Empty")
                                        } else {
                                            Text(KeyFormatter.format(from: viewModel.state.executorPublicKey))
                                        }

                                    }
                                    Spacer()
                                    if viewModel.state.canEdit {
                                        Button {
                                            actionSheetType = .editContractor(viewModel.state.deal.contractorPublicKey)

                                        } label: {
                                            Text(viewModel.state.executorPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit())
                                                .foregroundColor(R.color.textBase.color)
                                        }
                                        .buttonStyle(SecondaryMediumButton())
                                        .disabled(!viewModel.state.isOwnerDeal)
                                    }

                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))

                                Text("Performs the work specified in the contract")
                                    .font(.footnote)
                                    .foregroundColor(R.color.secondaryText.color)

                            }
                            .padding(16)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                        }
                        ZStack {
                            Circle()
                                .foregroundColor(R.color.mainBackground.color)
                                .frame(width: 28, height: 28)
                            (viewModel.state.ownerIsClient ?
                             Constants.arrowDownImage :
                                Constants.arrowUpImage).foregroundColor(R.color.secondaryText.color)
                        }
                        .frame(width: 28, height: 28)
                        .offset(CGSize(width: 20, height: -94))
                    }
                    Spacer(minLength: 16)

                    // MARK: - Verifier
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Verifier")
                                        .font(.footnote.weight(.semibold))
                                        .textCase(.uppercase)
                                        .foregroundColor(R.color.secondaryText.color)

                                    if viewModel.state.isYouVerifier {
                                        Label(text: R.string.localizable.commonYou(), type: .primary)
                                    }

                                }
                                if viewModel.state.deal.checkerPublicKey?.isEmpty ?? true {
                                    Text("Empty")
                                } else {
                                    Text(KeyFormatter.format(from: viewModel.state.deal.checkerPublicKey))
                                }

                            }
                            Spacer()
                            if viewModel.state.canEdit {
                                Button {
                                    actionSheetType = .editChecker(viewModel.state.deal.checkerPublicKey)

                                } label: {
                                    Text(R.string.localizable.commonEdit())
                                        .foregroundColor(R.color.textBase.color)
                                }
                                .buttonStyle(SecondaryMediumButton())
                                .disabled(!viewModel.state.isOwnerDeal)
                            }

                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                        if viewModel.state.isYouVerifier && viewModel.state.isOwnerDeal {
                            Text("After your verification of the result of the contract, the partner receives payment")
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        } else if (viewModel.state.deal.checkerPublicKey?.isEmpty ?? true) {
                            Text("You need set account for verification result of work by contract.")
                                .font(.footnote)
                                .foregroundColor(R.color.yellow.color)
                        } else {
                            Text("After verification by this Account of the result of the contract , the partner receives payment")
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }

                    }
                    .padding(16)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }

            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            Spacer(minLength: 16)
            VStack {
                // MARK: - Content
                VStack {
                    VStack {
                        HStack {
                            HStack {
                                Text("Text")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Label(text: R.string.localizable.commonYou(), type: .default)
                            }

                            Spacer()
                            Button {
                                viewModel.trigger(.decryptContent)
                            } label: {
                                if viewModel.state.deal.meta?.content != nil {
                                    Text(R.string.localizable.commonEdit())
                                } else {
                                    Text(R.string.localizable.commonAdd())
                                }
                            }
                            .buttonStyle(SecondaryMediumButton())

                        }
                        VStack(alignment: .leading) {
                            if let content = viewModel.state.deal.meta?.content {
                                HStack {
                                    Text(content.text)
                                    Spacer()
                                }

                            } else {
                                HStack {
                                    Text(R.string.localizable.commonEmpty())
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }
                Spacer(minLength: 4)
                VStack {
                    VStack {
                        HStack {
                            HStack {
                                Text("Files")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Label(text: R.string.localizable.commonYou(), type: .default)
                            }
                            Spacer()
                            Button {
                                uploaderState = .medium
                            } label: {
                                Text(R.string.localizable.commonAdd())
                            }
                            .buttonStyle(SecondaryMediumButton())

                        }
                        VStack(alignment: .leading) {
                            if viewModel.state.deal.meta?.files.isEmpty ?? true {
                                HStack {
                                    Text(R.string.localizable.commonEmpty())
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            } else {

                            }
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
                }
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)

                VStack(alignment: .leading) {
                    HStack {
                        Text("Results")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.textBase.color)

                        Label(text: "Waiting approve", type: .primary)
                        Spacer()
                    }
                    Text("Partner can publish documents for approve")
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)

                }
                .padding(EdgeInsets(top: 32, leading: 20, bottom: 16, trailing: 20))

                // MARK: - Results
                VStack {
                    VStack {
                        HStack {
                            HStack {
                                Text("Text")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Label(text: R.string.localizable.commonYou(), type: .default)
                            }

                            Spacer()
                            Button {
                                viewModel.trigger(.decryptContent)
                            } label: {
                                if viewModel.state.deal.meta?.content != nil {
                                    Text(R.string.localizable.commonEdit())
                                } else {
                                    Text(R.string.localizable.commonAdd())
                                }
                            }
                            .buttonStyle(SecondaryMediumButton())

                        }
                        VStack(alignment: .leading) {
                            if let content = viewModel.state.deal.meta?.content {
                                HStack {
                                    Text(content.text)
                                    Spacer()
                                }

                            } else {
                                HStack {
                                    Text(R.string.localizable.commonEmpty())
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }
                Spacer(minLength: 4)
                VStack {
                    VStack {
                        HStack {
                            HStack {
                                Text("Files")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Label(text: R.string.localizable.commonYou(), type: .default)
                            }
                            Spacer()
                            Button {
                                // TODO: -

                            } label: {
                                Text(R.string.localizable.commonAdd())
                            }
                            .buttonStyle(SecondaryMediumButton())

                        }
                        VStack(alignment: .leading) {
                            if viewModel.state.deal.meta?.files.isEmpty ?? true {
                                HStack {
                                    Text(R.string.localizable.commonEmpty())
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            } else {

                            }
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
                }
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                VStack {
                    Button {
                        viewModel.trigger(.sign)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign")
                            Spacer()
                        }
                    }
                    .buttonStyle(PrimaryLargeButton())
                    .disabled(!viewModel.state.canEdit)
                }
                .padding(EdgeInsets(top: 20, leading: 22, bottom: 50, trailing: 22))

            }
        }
        .resizableSheet($uploaderState, builder: { builder in
            builder.content { context in
                UploadFileView(
                    viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(account: viewModel.account, filesAPIService: try? APIServiceFactory.shared.makeFileService())))
                { result in
                    uploaderState = .hidden
                }
                .padding(16)
            }
            .animation(.easeOut.speed(1.8))
            .background { context in
                Color.black.opacity(
                    context.state == .medium ? context.progress * 0.8:
                        context.state == .large ? (1 + context.progress) * 0.8 :
                        0.0
                ).ignoresSafeArea()
            }
        })
        .sheet(item: $actionSheetType) { type in
            switch type {
            case .importSharedKey:
                ImportSecretKeyView { key in
                    guard let key = key else { return }
                    viewModel.trigger(.saveKey(key))
                }
            case .editContent(let content):
                TextEditorView(
                    content: content ?? "",
                    allowEdit: true)
                { newContent in
                    viewModel.trigger(.updateContent(newContent))
                } onDismiss: {
                    viewModel.trigger(.none)
                }.interactiveDismiss(canDismissSheet: false)
            case .changeAmount:
                ChangeAmountView(
                    viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(
                        ChangeAmountViewModel(
                            state: .init(
                                dealId: viewModel.state.deal.id,
                                amount: Amount(viewModel.deal.amount, currency: viewModel.deal.currency)),
                            dealService: try? APIServiceFactory.shared.makeDealsService())),
                    didChange: { newAmount in
                        viewModel.trigger(.changeAmount(newAmount))
                    })
            case .editContractor(let publicKey):
                AddContractorView(viewModel: AnyViewModel<AddContractorState, AddContractorInput>(AddContractorViewModel(
                    account: viewModel.state.account,
                    participateType: .contractor,
                    deal: viewModel.state.deal,
                    sharedSecretBase64: viewModel.state.sharedSecretBase64,
                    blockchain: viewModel.state.account.blockchain,
                    dealService: try? APIServiceFactory.shared.makeDealsService(),
                    publicKey: publicKey))
                ) { deal in
                    guard let deal = deal else {
                        actionSheetType = nil
                        return
                    }
                    viewModel.trigger(.update(deal))
                }
                .interactiveDismiss(canDismissSheet: false)
            case .editChecker(let publicKey):
                AddContractorView(viewModel: AnyViewModel<AddContractorState, AddContractorInput>(AddContractorViewModel(
                    account: viewModel.state.account,
                    participateType: .checker,
                    deal: viewModel.state.deal,
                    sharedSecretBase64: viewModel.state.sharedSecretBase64,
                    blockchain: viewModel.state.account.blockchain,
                    dealService: try? APIServiceFactory.shared.makeDealsService(),
                    publicKey: publicKey))
                ) { deal in
                    guard let deal = deal else {
                        actionSheetType = nil
                        return
                    }
                    viewModel.trigger(.update(deal))
                }
                .interactiveDismiss(canDismissSheet: false)
            }

        }
        .onChange(of: viewModel.state.state) { value in
            switch value {
            case .decryptedContent(let content):
                actionSheetType = .editContent(content)
            case .error(let errorMessage):
                self.alertType = .error(errorMessage)
            case .none:
                actionSheetType = nil
            case .loading, .success:
                break
            }
        }
        .alert(item: $alertType, content: { type in
            switch type {
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message))
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor()
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)

    }
}

extension DealView.ActiveSheetType: Identifiable {
    var id: String {
        switch self {
        case .editContent:
            return "editContent"
        case .changeAmount:
            return "changeAmount"
        case .editContractor:
            return "addContractor"
        case .importSharedKey:
            return "importSharedKey"
        case .editChecker:
            return "editChecker"
        }
    }
}

extension DealView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        }
    }
}

#if DEBUG
struct DealView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DealView(viewModel: AnyViewModel<DealState, DealInput>(
                DealViewModel(
                    state: DealState(account: Mock.account, deal: Mock.deal),
                    dealService: nil,
                    transactionSignService: nil,
                    secretStorage: nil)))
        }
    }
}
#endif
