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
import SafariServices
import BigInt
import SwiftUIPullToRefresh

fileprivate enum Constants {
    static let remove = Image(systemName: "xmark.circle.fill")
    static let dotsImage = Image(systemName: "ellipsis")
    static let dotsCircleImage = Image(systemName: "ellipsis.circle")
    static let arrowUpImage = Image(systemName: "arrow.up")
    static let arrowDownImage = Image(systemName: "arrow.down")
    static let rewardImage = Image(systemName: "purchased")
    static let lock = Image(systemName: "lock.fill")
    static let unlockedFile = Image(systemName: "lock.open.fill")
    static let file = Image(systemName: "doc.fill")
    static let lockFile = Image(systemName: "lock.doc.fill")
}

struct DealView: View {

    enum AlertType {
        case error(String)
    }

    enum ActionsSheetType: Equatable {
        case confirmCancel
        case dealActions
    }

    enum ActiveModalType: Equatable {
        case viewTextDealDetails
        case editTextDealDetails
        case editTextDealResult
        case editContractor(String?)
        case editChecker(String?)
        case changeAmount
        case changeCheckerAmount
        case importSharedKey
        case filePreview(URL)
        case shareSecret
        case confirm
        case confirmCancel
    }

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hudCoordinator: JGProgressHUDCoordinator

    @StateObject var viewModel: AnyViewModel<DealState, DealInput>
    let availableTokens: [ContractusAPI.Token]
    var callback: () -> Void

    @State private var activeModalType: ActiveModalType?
    @State private var alertType: AlertType?
    @State private var actionsType: ActionsSheetType?
    @State private var uploaderState: ResizableSheetState = .hidden
    @State private var uploaderContentType: DealsService.ContentType?
//    @State private var showActionMenu: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.state.state == .none && !viewModel.state.canEdit {
                    HStack(spacing: 1) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(R.string.localizable.dealNoSecretKey())
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                            Text(R.string.localizable.dealNoSecretKeyInformation())
                                .font(.footnote)
                                .multilineTextAlignment(.leading)

                        }
                        Spacer()

                        CButton(
                            title: R.string.localizable.commonImport(),
                            style: .primary,
                            size: .default,
                            isLoading: false)
                        {
                            activeModalType = .importSharedKey
                        }

                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .background(R.color.labelBackgroundAttention.color)
                    .cornerRadius(12)
                }
                VStack {
                    ZStack(alignment: .bottomLeading) {
                        VStack {
                            VStack(alignment: .leading) {
                                // MARK: - Client
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(R.string.localizable.dealTextClient())
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                            if viewModel.state.youIsClient {
                                                Label(text: R.string.localizable.commonYou(), type: .primary)
                                            }
                                            if viewModel.state.ownerIsClient {
                                                Label(text: R.string.localizable.commonOwner(), type: .success)
                                            }
                                        }
                                        if viewModel.state.clientPublicKey.isEmpty {
                                            Text(R.string.localizable.commonEmpty())
                                        } else {
                                            Text(ContentMask.mask(from: viewModel.state.clientPublicKey))
                                        }
                                    }
                                    Spacer()
                                    if viewModel.state.isYouExecutor && viewModel.state.canEdit {
                                        CButton(title: viewModel.state.clientPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false) {
                                            activeModalType = .editContractor(viewModel.state.deal.contractorPublicKey)
                                        }
                                    }

                                }.padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                                if viewModel.state.isYouExecutor && viewModel.state.canEdit {
                                    Text("Account that pays the performer for the work done")
                                        .font(.footnote)
                                        .foregroundColor(R.color.secondaryText.color)
                                }

                                Divider().foregroundColor(R.color.baseSeparator.color).padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))

                                // MARK: - Amount
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(R.string.localizable.dealViewAmount())
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }
                                        HStack(alignment: .lastTextBaseline) {
                                            Text(viewModel.state.deal.amountFormatted)
                                                .font(.largeTitle)
                                            Text(viewModel.state.deal.token.code).font(.footnote.weight(.semibold))
                                                .foregroundColor(R.color.secondaryText.color)
                                        }

                                    }
                                    Spacer()
                                    if viewModel.state.canEdit {
                                        CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false) {
                                            activeModalType = .changeAmount
                                        }
                                    }

                                }
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            }
                            .padding(14)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)

                            // MARK: - Executor
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(R.string.localizable.dealTextExecutor())
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)
                                            if viewModel.state.isYouExecutor {
                                                Label(text: R.string.localizable.commonYou(), type: .primary)
                                            }
                                            if viewModel.state.ownerIsExecutor {
                                                Label(text: R.string.localizable.commonOwner(), type: .success)
                                            }
                                        }
                                        if viewModel.state.executorPublicKey.isEmpty {
                                            Text(R.string.localizable.commonEmpty())
                                        } else {
                                            Text(ContentMask.mask(from: viewModel.state.executorPublicKey))
                                        }

                                    }
                                    Spacer()
                                    if viewModel.state.isOwnerDeal && viewModel.state.youIsClient {
                                        CButton(title: viewModel.state.executorPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false) {
                                            activeModalType = .editContractor(viewModel.state.executorPublicKey)
                                        }
                                    }

                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))

                                Text(R.string.localizable.dealHintAboutExecutor())
                                    .font(.footnote)
                                    .foregroundColor(R.color.secondaryText.color)

                            }
                            .padding(14)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                        }
                        ZStack {
                            Circle()
                                .foregroundColor(R.color.mainBackground.color)
                                .frame(width: 28, height: 28)
                            Constants.arrowDownImage.foregroundColor(R.color.secondaryText.color)
                        }
                        .frame(width: 28, height: 28)
                        .offset(CGSize(width: 20, height: -93))
                    }
//                    Spacer(minLength: 16)

                    // MARK: - Verifier
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(R.string.localizable.dealTextVerifier())
                                        .font(.footnote.weight(.semibold))
                                        .textCase(.uppercase)
                                        .foregroundColor(R.color.secondaryText.color)
                                }
                                HStack {
                                    if viewModel.state.isYouChecker {
                                        Text(R.string.localizable.commonYou())
                                    } else if viewModel.state.deal.checkerPublicKey?.isEmpty ?? true {
                                        if !viewModel.state.clientPublicKey.isEmpty {
                                            Text(ContentMask.mask(from: viewModel.state.clientPublicKey))
                                            Label(text: R.string.localizable.commonOwner(), type: .primary)
                                        } else {
                                            Text(R.string.localizable.commonEmpty())
                                        }
                                    } else {
                                        Text(ContentMask.mask(from: viewModel.state.deal.checkerPublicKey))
                                    }
                                }
                            }
                            Spacer()
//                            if viewModel.state.isOwnerDeal && !viewModel.state.isYouChecker {
//                                CButton(title: "", icon: Constants.rewardImage, style: .secondary, size: .default, isLoading: false) {
//                                    activeModalType = .changeCheckerAmount
//                                }
//                            }

                            // TODO: - Add feature: change verifier
//                            if viewModel.state.isOwnerDeal && viewModel.state.canEdit {
//                                CButton(title: R.string.localizable.commonChange(), style: .secondary, size: .default, isLoading: false) {
//                                    activeModalType = .editChecker(viewModel.state.deal.checkerPublicKey)
//                                }
//                            }

                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                        if viewModel.state.isYouChecker {
                            Text(R.string.localizable.dealHintYouVerifier())
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        else if (viewModel.state.deal.checkerPublicKey?.isEmpty ?? true && viewModel.state.isOwnerDeal) {
                            Text(R.string.localizable.dealHintEmptyVerifier())
                                .font(.footnote)
                                .foregroundColor(R.color.textWarn.color)
                        }
                        else if viewModel.state.isYouExecutor {
                            Text(R.string.localizable.dealHintYouExecutor())
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        } else {
                            Text(R.string.localizable.dealHintVerifier())
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }

                    }
                    .padding(14)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }

            }
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))

            HStack {
                Text(R.string.localizable.dealTextDetails())
                    .font(.title.weight(.regular))
                Spacer()
            }
            .padding(EdgeInsets(top: 20, leading: 12, bottom: 12, trailing: 12))

            VStack {
                // MARK: - Content
                VStack {
                    VStack {
                        HStack {
                            HStack(spacing: 8) {
                                Text(R.string.localizable.dealTextText())
                                    .font(.title3.weight(.regular))
                                if !(viewModel.state.deal.meta?.contentIsEmpty ?? true) {
                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }
                            }

                            Spacer()
                            if viewModel.state.canEdit {
                                CButton(title: (viewModel.state.deal.meta?.contentIsEmpty ?? true) ? R.string.localizable.commonSet() : R.string.localizable.commonOpen(), style: .secondary, size: .default, isLoading: false) {
                                    if self.viewModel.isYouChecker && !self.viewModel.state.isOwnerDeal {
                                        activeModalType = .viewTextDealDetails
                                    } else {
                                        activeModalType = .editTextDealDetails
                                    }
                                }
                            }

                        }
                        VStack(alignment: .leading) {
                            if let content = viewModel.state.deal.meta?.content {
                                HStack {
                                    Text(ContentMask.maskAll(content.text))
                                    Spacer()
                                }

                            } else {
                                HStack {
                                    Text("This text will be encrypted and available for viewing only to contract partners.")
                                        .font(.footnote)
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 22, leading: 26, bottom: 22, trailing: 26))
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }
                Spacer(minLength: 4)
                VStack {
                    VStack(spacing: 8) {
                        HStack {
                            HStack {
                                Text(R.string.localizable.dealTextFiles())
                                    .font(.title3.weight(.regular))
                            }
                            Spacer()
                            if viewModel.state.canEdit {
                                CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false) {
                                    uploaderState = .medium
                                    uploaderContentType = .metadata
                                }
                            }

                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.state.deal.meta?.files.isEmpty ?? true {
                                HStack {
                                    Text("This files will be encrypted and available for viewing only to contract partners.")
                                        .font(.footnote)
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            } else {
                                ForEach(viewModel.state.deal.meta?.files ?? []) { file in
                                    FileItemView(
                                        file: file,
                                        decryptedName: viewModel.state.decryptedFiles[file.md5]?.lastPathComponent)
                                    { action in

                                        switch action {
                                        case .open:
                                            viewModel.trigger(.openFile(file))
                                        case .delete:
                                            viewModel.trigger(.deleteMetadataFile(file))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 22, leading: 26, bottom: 22, trailing: 26))
                }
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                if viewModel.state.showResult {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(R.string.localizable.dealResultsTitle())
                                .font(.title.weight(.regular))
//                                .textCase(.uppercase)
                                .foregroundColor(R.color.textBase.color)

                            Label(text: R.string.localizable.dealResultsWaitingApprove(), type: .primary)
                            Spacer()
                        }
                        Text(R.string.localizable.dealResultsHint())
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)

                    }
                    .padding(EdgeInsets(top: 32, leading: 26, bottom: 16, trailing: 26))

                    // MARK: - Results
                    VStack {
                        VStack {
                            HStack {
                                HStack {
                                    Text(R.string.localizable.dealTextText())
                                        .font(.title2.weight(.regular))
                                        .fontWeight(.semibold)

                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }

                                Spacer()

                                if viewModel.state.canSendResult {
                                    CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false) {
                                        activeModalType = .editTextDealResult
                                    }
                                } else {
                                    CButton(title: R.string.localizable.commonView(), style: .secondary, size: .default, isLoading: false) {
                                        // TODO: -
                                    }
                                }
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
                                    Text(R.string.localizable.dealTextFiles())
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }
                                Spacer()
                                CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false) {
                                    uploaderState = .medium
                                    uploaderContentType = .result
                                }

                            }
                            VStack(alignment: .leading) {
                                if viewModel.state.deal.results?.files.isEmpty ?? true {
                                    HStack {
                                        Text(R.string.localizable.commonEmpty())
                                            .foregroundColor(R.color.secondaryText.color)
                                        Spacer()
                                    }
                                } else {
                                    if let files = viewModel.state.deal.results?.files {
                                        ForEach(files) { file in
                                            FileItemView(file: file) { action in
                                                switch action {
                                                case .open:
                                                    viewModel.trigger(.openFile(file))
                                                case .delete:
                                                    viewModel.trigger(.deleteResultFile(file))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
                    }
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                }

                // MARK: - Actions
                VStack {

                    VStack(alignment: .center, spacing: 12) {
                        ForEach(viewModel.currentMainActions) { actionType in
                            switch actionType {
                            case .sign:
                                if viewModel.state.isSignedByPartner {
                                    CButton(title: "Sign and start", style: .primary, size: .large, isLoading: false) {
                                        activeModalType = .confirm
                                    }
                                    Text("The partner has already signed the contract. The work of the contract will begin when you sign the contract.")
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(R.color.labelBackgroundAttention.color)
                                } else {
                                    CButton(title: "Sign", style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.state.canSign) {
                                        activeModalType = .confirm
                                    }
                                    Text("Sign the contract, the work of the contract starts automatically when your partner signs it")
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(R.color.labelBackgroundAttention.color)
                                }
                            case .cancelSign:
                                CButton(title: "Cancel sign", style: .cancel, size: .large, isLoading: false) {
                                    viewModel.trigger(.cancelSign)

                                }
                                Text("You can cancel your signature before your partner signs the contract. The work of the contract will begin when the partner signs.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(R.color.labelBackgroundAttention.color)
                            case .cancelDeal:
                                CButton(title: "Cancel deal", style: .cancel, size: .large, isLoading: false) {
                                    // TODO: - Add
                                }
                                Text("You can cancel the contract all funds will be refunded.")
                                    .font(.footnote)
                                    .foregroundColor(R.color.yellow.color)
                            case .finishDeal:
                                CButton(title: "Finish deal", style: .primary, size: .large, isLoading: false) {
                                    // TODO: - Add
                                }
                                Text("If all the work is done as specified in the contract you can complete the contract, the contractor will receive payment. The checker will receive a commission for services.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(R.color.labelBackgroundAttention.color)
                            }
                        }
                    }

                }
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 24, trailing: 20))
            }
        }
        .refreshableCompat(loadingViewBackgroundColor: .clear, onRefresh: { done in
            viewModel.trigger(.update(nil)) {
                done()
            }
        }, progress: { state in
            RefreshActivityIndicator(isAnimating: state == .loading) {
                $0.hidesWhenStopped = false
            }
        })
        .resizableSheet($uploaderState, builder: { builder in
            builder.content { context in
                uploaderView()
            }
            .animation(.easeOut.speed(1.8))
            .background { context in
                Color.black
                    .opacity(context.state == .medium ? 0.5 : 0)
                    .ignoresSafeArea()
            }
            .supportedState([.medium])
        })

        .sheet(item: $activeModalType) { type in
            switch type {
            case .confirmCancel:
                // TODO: -
                EmptyView()
            case .confirm:
                TransactionSignView(account: viewModel.state.account, type: .byDeal(viewModel.state.deal)) {
                    viewModel.trigger(.updateTx)
                    callback()
                    
                } cancelAction: {
                    // TODO: - Cancel
                }
                .interactiveDismiss(canDismissSheet: false)
            case .importSharedKey:
                QRCodeScannerView(configuration: .scannerAndInput, blockchain: viewModel.state.account.blockchain) { result in

                    viewModel.trigger(.saveKey(result))
                    activeModalType = nil
                }
            case .editTextDealDetails, .viewTextDealDetails:
                TextEditorView(allowEdit: type == .editTextDealDetails, viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(
                    dealId: viewModel.state.deal.id,
                    content: viewModel.state.deal.meta ?? .init(files: []),
                    contentType: .metadata,
                    secretKey: viewModel.state.decryptedKey,
                    dealService: try? APIServiceFactory.shared.makeDealsService())),
                               action: { result in

                    switch result {
                    case .close:
                        activeModalType = nil
                    case .success(let meta):
                        viewModel.trigger(.updateContent(meta, .metadata))
                    }

                })
                .interactiveDismiss(canDismissSheet: false)
            case .editTextDealResult:
                TextEditorView(allowEdit: true, viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(
                    dealId: viewModel.state.deal.id,
                    content: viewModel.state.deal.results ?? .init(files: []),
                    contentType: .result,
                    secretKey: viewModel.state.decryptedKey, dealService: try? APIServiceFactory.shared.makeDealsService())),
                               action: { result in

                    switch result {
                    case .close:
                        activeModalType = nil
                    case .success(let meta):
                        viewModel.trigger(.updateContent(meta, .result))
                    }

                })
                .interactiveDismiss(canDismissSheet: false)
            case .changeAmount, .changeCheckerAmount:
                ChangeAmountView(
                    viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(
                        ChangeAmountViewModel(
                            deal: viewModel.state.deal,
                            account: viewModel.state.account,
                            amountType: type == .changeAmount ? .deal : .checker,
                            dealService: try? APIServiceFactory.shared.makeDealsService())),
                    availableTokens: availableTokens,
                    didChange: { newAmount, typeAmount in
                        switch typeAmount {
                        case .deal:
                            viewModel.trigger(.changeAmount(newAmount))
                        case .checker:
                            viewModel.trigger(.changeCheckerAmount(newAmount))
                        }

                    })
                .interactiveDismiss(canDismissSheet: false)
            case .editContractor(let publicKey):
                AddContractorView(viewModel: AnyViewModel<AddContractorState, AddContractorInput>(AddContractorViewModel(
                    account: viewModel.state.account,
                    participateType: .contractor,
                    deal: viewModel.state.deal,
                    sharedSecretBase64: viewModel.state.partnerSecretPartBase64,
                    blockchain: viewModel.state.account.blockchain,
                    dealService: try? APIServiceFactory.shared.makeDealsService(),
                    publicKey: publicKey))
                ) { deal in
                    guard let deal = deal else {
                        activeModalType = nil
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
                    sharedSecretBase64: viewModel.state.partnerSecretPartBase64,
                    blockchain: viewModel.state.account.blockchain,
                    dealService: try? APIServiceFactory.shared.makeDealsService(),
                    publicKey: publicKey))
                ) { deal in
                    guard let deal = deal else {
                        activeModalType = nil
                        return
                    }
                    viewModel.trigger(.update(deal))
                }
                .interactiveDismiss(canDismissSheet: false)
            case .filePreview(let url):
                QuickLookView(url: url) {

                }
            case .shareSecret:
                if let shareData = viewModel.state.shareDeal {
                    ShareContentView(
                        contentType: .privateKey,
                        informationType: .none,
                        content: shareData,
                        topTitle: "Share",
                        title: "The secret key",
                        subTitle: "The partner need scan the QR code to start working on the contract.")
                    { _ in
                        // TODO: -
                    } dismissAction: {
                        activeModalType = .none
                    }
                }
            }

        }
        .onChange(of: viewModel.state.state) { value in
            switch value {
            case .none:
                activeModalType = nil
            case .loading, .success:
                break
            }
        }
        .onChange(of: viewModel.state.errorState) { value in
            switch value {
            case .error(let errorMessage):
                self.alertType = .error(errorMessage)
            case .none:
                self.alertType = nil
            }
        }
        .onChange(of: viewModel.state.previewState) { value in
            switch value {
            case .none:
                activeModalType = .none
            case .filePreview(let url):
                activeModalType = .filePreview(url)
                dismissHUD()
            case .downloading(let progress):
                debugPrint("Progress - \(progress)")
                updateProgressHUD(progress: progress)
            case .decrypting:
                decryptingHUD()

            }
        }
        .alert(item: $alertType, content: { type in
            switch type {
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message),
                    dismissButton: .default(Text("Ok"), action: {
                        viewModel.trigger(.hideError)
                    }))
            }
        })

        .actionSheet(item: $actionsType, content: { type in
            switch type {
            case .confirmCancel:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetMenuButtons())
            case .dealActions:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetMenuButtons())
            }
        })
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.state.isOwnerDeal {
                    Button {
                        actionsType = .dealActions
                    } label: {
                        Constants.dotsImage
                    }
                }
            }
        }
        .navigationBarTitle(R.string.localizable.commonDeal())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor()
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)

    }

    @ViewBuilder
    private func uploaderView() -> some View {
        UploadFileView(
            viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(
                dealId: viewModel.state.deal.id,
                content: uploaderContentType == .result ? viewModel.state.deal.results ?? .init(files: []) : viewModel.state.deal.meta ?? .init(files: []),
                contentType: uploaderContentType ?? .metadata,
                secretKey: viewModel.state.decryptedKey,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                filesAPIService: try? APIServiceFactory.shared.makeFileService())), action: { actionType in
            switch actionType {
            case .close:
                uploaderState = .hidden
                uploaderContentType = nil

            case .success(let meta, let contentType):
                viewModel.trigger(.updateContent(meta, contentType))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    uploaderState = .hidden
                    uploaderContentType = nil
                })
            }
        })
        .padding(16)
    }

    private func actionSheetMenuButtons() -> [Alert.Button] {
        if viewModel.isOwnerDeal {
            return [
                Alert.Button.default(Text("Share Secret")) {
                     activeModalType = .shareSecret
                },
                Alert.Button.destructive(Text("Cancel deal")) {
                    viewModel.trigger(.cancel) {
                        self.callback()
                        self.presentationMode.wrappedValue.dismiss()
                    }
                },
                Alert.Button.cancel() {

                }]
        }
        return [
            Alert.Button.destructive(Text("Decline")) {
                viewModel.trigger(.cancel) {
                    self.callback()
                    self.presentationMode.wrappedValue.dismiss()
                }
            },
        ]
    }

    private func updateProgressHUD(progress: Double) {
        if let hud = hudCoordinator.presentedHUD {
            hud.progress = Float(progress)
            return
        }
        hudCoordinator.showHUD {
            let hud = CHUD()
            hud.textLabel.text = "Downloading"
            hud.indicatorView = JGProgressHUDPieIndicatorView()
            hud.progress = Float(progress)
            hud.cancelPressedAction = {
                ImpactGenerator.soft()
                viewModel.trigger(.cancelDownload)
                hud.dismiss()
            }
            return hud
        }
    }

    private func decryptingHUD() {
        let text = "Decrypting"
        if let hud = hudCoordinator.presentedHUD {
            hud.textLabel.text = text
            hud.indicatorView = JGProgressHUDIndicatorView()
            hud.cancelPressedAction = nil
            return
        }

        hudCoordinator.showHUD {
            let hud = CHUD()
            hud.textLabel.text = text
            hud.indicatorView = JGProgressHUDIndicatorView()
            hud.cancelPressedAction = nil
            return hud
        }
    }

    private func dismissHUD() {
        hudCoordinator.presentedHUD?.dismiss()
    }
}


struct FileItemView: View {

    enum ActionType {
        case open, delete
    }
    var file: MetadataFile
    var decryptedName: String?
    var action: (Self.ActionType) -> Void

    @State private var confirmPresented: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Button {
                action(.open)
            } label: {

                HStack(alignment: .center, spacing: 6) {
                    if decryptedName != nil  {
                        Constants.file
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(R.color.yellow.color)
                    } else {
                        Constants.lockFile
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(R.color.secondaryText.color)

                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(decryptedName ?? file.name)
                            .lineLimit(1)
                            .font(.callout.weight(.medium))
                            .foregroundColor(R.color.textBase.color)
                            .truncationMode(.middle)

                        HStack(spacing: 12) {
                            Text(FileSizeFormatter.shared.format(file.size))
                                .multilineTextAlignment(.leading)
                                .font(.footnote.weight(.regular))
                                .foregroundColor(R.color.secondaryText.color)

                        }
                        .frame(height: 14)
                    }
                }

            }

            Spacer()
            Button {
                confirmPresented = true
            } label: {
                Constants.remove
                    .resizable()
                    .foregroundColor(R.color.secondaryText.color)
                    .frame(width: 16, height: 16)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
        .padding(.bottom, 8)
        .confirmationDialog("", isPresented: $confirmPresented) {
            Button("Yes, delete", role: .destructive) {
                action(.delete)
            }
        } message: {
            Text("You want delete file?")
        }

    }
}

extension DealView.ActiveModalType: Identifiable {
    var id: String {
        return "\(self)"
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

extension DealView.ActionsSheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

#if DEBUG
struct DealView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DealView(viewModel: AnyViewModel<DealState, DealInput>(
                DealViewModel(
                    state: DealState(account: Mock.account, availableTokens: SolanaTokens.list, deal: Mock.deal, isSignedByPartner: true),
                    dealService: nil,
                    transactionSignService: nil,
                    filesAPIService: nil,
                    secretStorage: nil)),
                     availableTokens: SolanaTokens.list) {
                        
                    }
        }
        .previewDisplayName("Form")
        VStack {
            FileItemView(file: Mock.metadataFile) {_ in

            }
            FileItemView(file: Mock.metadataFile) { _ in

            }
            FileItemView(file: Mock.metadataFileLock, decryptedName: "[No file name]") { _ in

            }
        }
        .previewDisplayName("File items")


    }
}

#endif
