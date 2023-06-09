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
    static let shieldImage = Image(systemName: "checkmark.shield.fill")
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
        case confirmClear
    }

    enum ActionsSheetType: Equatable {
        case confirmCancel
        case dealActions
        case confirmCancelSign
        case confirmFinish
        case executorActions
    }

    enum ActiveModalType: Equatable {
        case viewTextDealDetails
        case editTextDealDetails
        case viewTextDealResult
        case editTextDealResult
        case editContractor(String?)
        case editChecker(String?)
        case changeAmount
        case changeCheckerAmount
        case changeContractorBond
        case changeOwnerBond
        case importSharedKey
        case filePreview(URL)
        case shareSecret
        case signTx(TransactionType)
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
    @State private var showDeadlinePicker: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.state.state == .none && !viewModel.state.canEdit {
                    HStack(spacing: 1) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(R.string.localizable.dealNoSecretKey())
                                .foregroundColor(R.color.textBase.color)
                                .font(.body.weight(.semibold))
                                .multilineTextAlignment(.leading)
                            Text(R.string.localizable.dealNoSecretKeyInformation())
                                .font(.footnote)
                                .foregroundColor(R.color.textBase.color)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()

                        CButton(
                            title: R.string.localizable.commonImport(),
                            style: .warn,
                            size: .default,
                            isLoading: false) {
                                activeModalType = .importSharedKey
                            }
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .background {
                        RoundedRectangle(cornerRadius: 20).stroke().fill(R.color.yellow.color)
                    }
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
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
                                    if !viewModel.state.ownerIsClient && viewModel.state.isYouExecutor {
                                        CButton(title: viewModel.state.clientPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false, isDisabled: !viewModel.state.canEdit) {
                                            activeModalType = .editContractor(viewModel.state.deal.contractorPublicKey)
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                                if viewModel.state.isYouExecutor && viewModel.state.canEdit {
                                    Text(R.string.localizable.dealHintPayAccount())
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
                                                .font(.title)
                                            Text(viewModel.state.deal.token.code).font(.footnote.weight(.semibold))
                                                .foregroundColor(R.color.secondaryText.color)
                                        }

                                    }
                                    Spacer()
                                    if viewModel.state.canEditDeal {
                                        CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false, isDisabled: !viewModel.state.canEdit) {
                                            activeModalType = .changeAmount
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            }
                            .padding(14)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                            .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)

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
                                    if viewModel.state.isOwnerDeal && viewModel.state.youIsClient && viewModel.state.canEditDeal {
                                        CButton(title: viewModel.state.executorPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false) {
                                            if viewModel.state.executorPublicKey.isEmpty {
                                                activeModalType = .editContractor(viewModel.state.executorPublicKey)
                                            } else {
                                                actionsType = .executorActions
                                            }
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
                            .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
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
                    if viewModel.state.deal.completionCheckType == .checker {
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
                                if viewModel.state.isOwnerDeal || viewModel.state.isYouChecker {
                                    CButton(title: "", icon: Constants.rewardImage, style: .secondary, size: .default, isLoading: false) {
                                        activeModalType = .changeCheckerAmount
                                    }
                                }

                                if viewModel.state.isOwnerDeal && viewModel.state.canEdit {
                                    CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false) {
                                        activeModalType = .editChecker(viewModel.state.deal.checkerPublicKey)
                                    }
                                }

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
                        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                    }

                    switch viewModel.state.deal.performanceBondType {
                    case .none:
                        EmptyView()
                    default:

                        HStack(alignment: .center) {
                            Constants.shieldImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 21, height: 21)
                                .foregroundColor(R.color.secondaryText.color)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Performance bond")
                                    .foregroundColor(R.color.textBase.color)
                                    .font(.title3)

                                Text("This is guarantee to mitigate the risks. ")
                                    .foregroundColor(R.color.secondaryText.color)
                                    .font(.footnote)

                            }

                            Spacer()
                        }
                        .padding(EdgeInsets(top: 16, leading: 4, bottom: 0, trailing: 4))

                        VStack(alignment: .leading, spacing: 0) {
                            // MARK: - Bond
                            if viewModel.state.deal.performanceBondType == .onlyClient ||
                                viewModel.state.deal.performanceBondType == .both {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Client")
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            if viewModel.state.clientBondAmount.isEmpty {
                                                Text(R.string.localizable.commonEmpty())
                                                    .font(.title)

                                            } else {
                                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                    Text(viewModel.state.clientBondAmount)
                                                        .font(.title)
                                                    Text(viewModel.state.clientBondToken?.code ?? "").font(.footnote.weight(.semibold))
                                                        .foregroundColor(R.color.secondaryText.color)
                                                }
                                            }
                                            Text("Upon completion the funds will be returned to the client")
                                                .font(.footnote)
                                                .foregroundColor(R.color.secondaryText.color)
                                        }
                                    }
                                    Spacer()
                                    if viewModel.state.canEditDeal {
                                        CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false, isDisabled: !(viewModel.state.isOwnerDeal)) {
                                            activeModalType = !viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))

                            }
                            if viewModel.state.deal.performanceBondType == .both {
                                Divider().foregroundColor(R.color.baseSeparator.color).padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
                            }

                            if viewModel.state.deal.performanceBondType == .onlyExecutor ||
                                viewModel.state.deal.performanceBondType == .both {

                                // MARK: - Executor
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Executor")
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }
                                        VStack(alignment: .leading, spacing: 8) {
                                            if viewModel.state.executorBondAmount.isEmpty {
                                                Text(R.string.localizable.commonEmpty())
                                                    .font(.title)

                                            } else {
                                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                    Text(viewModel.state.executorBondAmount)
                                                        .font(.title)
                                                    Text(viewModel.state.executorBondToken?.code ?? "").font(.footnote.weight(.semibold))
                                                        .foregroundColor(R.color.secondaryText.color)
                                                }
                                            }

                                            Text("Upon completion the funds will be returned to the executor")
                                                .font(.footnote)
                                                .foregroundColor(R.color.secondaryText.color)
                                        }
                                    }
                                    Spacer()
                                    if viewModel.state.canEditDeal {
                                        CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false, isDisabled: !(viewModel.state.isOwnerDeal)) {
                                            activeModalType = viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            }

                        }
                        .padding(14)
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)

                        // MARK: - Deadline
                        if viewModel.state.deal.performanceBondType == .both {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Deadline")
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                                if let deadline = viewModel.state.deal.deadline {
                                                    Text(deadline.asDateFormatted())
                                                        .font(.title)
                                                } else {
                                                    Text(R.string.localizable.commonEmpty())
                                                        .font(.title)
                                                }

                                            }
                                            Text("If the counter parties do not agree before the appointed date, the contract is terminated and the funds are returned to all parties.")
                                                .font(.footnote)
                                                .foregroundColor(R.color.secondaryText.color)

                                        }
                                        .popover(isPresented: $showDeadlinePicker) {
                                            DeadlineView(
                                                viewModel: .init(DeadlineViewModel(
                                                    deal: viewModel.state.deal,
                                                    account: viewModel.state.account,
                                                    dealService: try? APIServiceFactory.shared.makeDealsService()))) { updatedDeal in
                                                        viewModel.trigger(.update(updatedDeal))

                                                }
                                        }
                                    }
                                    Spacer()
                                    if viewModel.state.canEditDeal {
                                        CButton(title: R.string.localizable.commonEdit(), style: .secondary, size: .default, isLoading: false, isDisabled: !(viewModel.state.isOwnerDeal)) {
                                            showDeadlinePicker.toggle()
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                            }
                            .padding(14)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                            .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                        }

                    }

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
                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 8) {
                                Text(R.string.localizable.dealTextText())
                                    .font(.title3.weight(.regular))
                                if !(viewModel.state.deal.meta?.contentIsEmpty ?? true) {
                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }
                            }

                            Spacer()
                            if viewModel.state.canEditDeal {
                                CButton(title: (viewModel.state.deal.meta?.contentIsEmpty ?? true) ? R.string.localizable.commonSet() : R.string.localizable.commonOpen(), style: .secondary, size: .default, isLoading: false, isDisabled: !viewModel.state.canEdit) {
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
                                    Text(R.string.localizable.dealHintEncryptContent())
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
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
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
                            if viewModel.state.canEditDeal {
                                CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false, isDisabled: !viewModel.state.canEdit) {
                                    uploaderState = .medium
                                    viewModel.trigger(.uploaderContentType(.metadata))
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.state.deal.meta?.files.isEmpty ?? true {
                                HStack {
                                    Text(R.string.localizable.dealHintEncryptFiles())
                                        .font(.footnote)
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                            } else {
                                ForEach(viewModel.state.deal.meta?.files ?? []) { file in
                                    FileItemView(
                                        file: file,
                                        decryptedName: viewModel.state.decryptedFiles[file.md5]?.lastPathComponent
                                    ) { action in
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
                .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)

                if viewModel.state.showResult {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(R.string.localizable.dealResultsTitle())
                                .font(.title.weight(.regular))
                                .foregroundColor(R.color.textBase.color)

                            Label(text: R.string.localizable.dealResultsWaitingApprove(), type: .primary)
                            Spacer()
                        }
                        Text(R.string.localizable.dealResultsHint())
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)

                    }
                    .padding(EdgeInsets(top: 20, leading: 12, bottom: 12, trailing: 12))

                    // MARK: - Results
                    VStack {
                        VStack {
                            HStack {
                                HStack {
                                    Text(R.string.localizable.dealTextText())
                                        .font(.title3.weight(.regular))

                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }

                                Spacer()

                                if viewModel.state.canSendResult {
                                    CButton(title: (viewModel.state.deal.result?.contentIsEmpty ?? true) ? R.string.localizable.commonAdd() : R.string.localizable.commonOpen(), style: .secondary, size: .default, isLoading: false) {
                                        activeModalType = .editTextDealResult
                                    }
                                } else {
                                    CButton(title: R.string.localizable.commonView(), style: .secondary, size: .default, isLoading: false) {
                                        activeModalType = .viewTextDealResult
                                    }
                                }
                            }
                            VStack(alignment: .leading) {
                                if let result = viewModel.state.deal.result?.content {
                                    HStack {
                                        Text(ContentMask.maskAll(result.text))
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
                                        .font(.title3.weight(.regular))
                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }
                                Spacer()
                                if viewModel.state.canSendResult {
                                    CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false) {
                                        uploaderState = .medium
                                        viewModel.trigger(.uploaderContentType(.result))
                                    }
                                }
                            }
                            VStack(alignment: .leading) {
                                if viewModel.state.deal.result?.files.isEmpty ?? true {
                                    HStack {
                                        Text(R.string.localizable.commonEmpty())
                                            .foregroundColor(R.color.secondaryText.color)
                                        Spacer()
                                    }
                                } else {
                                    if let files = viewModel.state.deal.result?.files {
                                        ForEach(files) { file in
                                            FileItemView(
                                                file: file,
                                                decryptedName: viewModel.state.decryptedFiles[file.md5]?.lastPathComponent
                                            ) { action in
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
                    .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                }

                // MARK: - Actions
                VStack {
                    VStack(alignment: .center, spacing: 12) {
                        ForEach(viewModel.currentMainActions) { actionType in
                            switch actionType {
                            case .sign:
                                if viewModel.state.isSignedByPartner {
                                    CButton(title: R.string.localizable.dealButtonsSignAndStart(), style: .primary, size: .large, isLoading: false) {
                                        activeModalType = .signTx(.dealInit)
                                    }
                                    Text(R.string.localizable.dealDescriptionCommandPartnerAlreadySigned())
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(R.color.labelBackgroundAttention.color)
                                } else {
                                    CButton(title: R.string.localizable.dealButtonsSign(), style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.state.canSign) {
                                        activeModalType = .signTx(.dealInit)
                                    }
                                    if viewModel.state.canSign {
                                        Text(R.string.localizable.dealDescriptionCommandFirstSign())
                                            .font(.footnote)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(R.color.labelBackgroundAttention.color)
                                    } else {
                                        Text(R.string.localizable.dealDescriptionCommandCantSign())
                                            .font(.footnote)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(R.color.labelBackgroundAttention.color)
                                    }
                                }
                            case .cancelSign:
                                CButton(title: R.string.localizable.dealButtonsCancelSign(), style: .cancel, size: .large, isLoading: false) {
                                    actionsType = .confirmCancelSign
                                }
                                Text(R.string.localizable.dealDescriptionCommandCancelSign())
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(R.color.labelBackgroundAttention.color)
                            case .cancelDeal:
                                CButton(title: R.string.localizable.dealButtonsCancelDeal(), style: .cancel, size: .large, isLoading: false) {
                                    actionsType = .confirmCancel
                                }
                                Text(R.string.localizable.dealDescriptionCommandStopDeal())
                                    .font(.footnote)
                                    .foregroundColor(R.color.yellow.color)
                            case .finishDeal:
                                CButton(title: R.string.localizable.dealButtonsFinishDeal(), style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.state.isYouChecker) {
                                    actionsType = .confirmFinish
                                }
                                Text(R.string.localizable.dealDescriptionCommandFinishDeal())
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

        .sheet(item: $activeModalType, onDismiss: {
            viewModel.trigger(.sheetClose)
        }) { type in
            switch type {
            case .signTx(let type):
                TransactionSignView(account: viewModel.state.account, type: .byDeal(viewModel.state.deal, type)) {
                    viewModel.trigger(.update(nil))
                    callback()
                } closeAction: { afterSign in
                    // TODO: - Close
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
            case .editTextDealResult, .viewTextDealResult:
                TextEditorView(allowEdit: type == .editTextDealResult, viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(
                    dealId: viewModel.state.deal.id,
                    content: viewModel.state.deal.result ?? .init(files: []),
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
                            dealService: try? APIServiceFactory.shared.makeDealsService(),
                            tier: viewModel.state.tier
                        )
                    ),
                    availableTokens: availableTokens,
                    didChange: { newAmount, typeAmount, allowHolderMode in
                        switch typeAmount {
                        case .deal:
                            viewModel.trigger(.changeAmount(newAmount, allowHolderMode))
                        case .checker:
                            viewModel.trigger(.changeCheckerAmount(newAmount))
                        case .ownerBond:
                            break
                        case .contractorBond:
                            break
                        }
                    })
                .interactiveDismiss(canDismissSheet: false)
            case .changeOwnerBond, .changeContractorBond:
                ChangeAmountView(
                    viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(
                        ChangeAmountViewModel(
                            deal: viewModel.state.deal,
                            account: viewModel.state.account,
                            amountType: type == .changeOwnerBond ? .ownerBond : .contractorBond,
                            dealService: try? APIServiceFactory.shared.makeDealsService(),
                            tier: viewModel.state.tier
                        )
                    ),
                    availableTokens: availableTokens,
                    didChange: { newAmount, typeAmount, allowHolderMode in
                        switch typeAmount {
                        case .deal:
                            viewModel.trigger(.changeAmount(newAmount, allowHolderMode))
                        case .checker:
                            viewModel.trigger(.changeCheckerAmount(newAmount))
                        case .ownerBond:
                            viewModel.trigger(.changeOwnerBondAmount(newAmount))
                        case .contractorBond:
                            viewModel.trigger(.changeContractorBondAmount(newAmount))
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
                        topTitle: R.string.localizable.commonShare(),
                        title: R.string.localizable.shareContentTitleSecretKey(),
                        subTitle: R.string.localizable.shareContentSubtitleSecretKey())
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
                dismissHUD()
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
                    dismissButton: .default(Text(R.string.localizable.commonOk())) {
                        viewModel.trigger(.hideError)
                    }
                )
            case .confirmClear:
                return Alert(
                    title: Text(R.string.localizable.dealExecutorClearAccount()),
                    message: Text(R.string.localizable.dealExecutorClearAccountMessage()),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text(R.string.localizable.dealExecutorClearAccountConfirm())) {
                        viewModel.trigger(.deleteContractor(.contractor))
                    }
                )
            }
        })

        .actionSheet(item: $actionsType, content: { type in
            switch type {
            case .confirmCancel:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetCancelButtons())
            case .dealActions:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetMenuButtons())
            case .confirmCancelSign:
                return ActionSheet(
                    title: Text(R.string.localizable.dealCancelSignTitle()),
                    buttons: actionSheetCancelSignButtons())
            case .confirmFinish:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetFinishButtons())
            case .executorActions:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetEditExecutorButtons())
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
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)

    }

    @ViewBuilder
    private func uploaderView() -> some View {
        UploadFileView(
            viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(
                dealId: viewModel.state.deal.id,
                content: viewModel.state.uploaderContentType == .result ? viewModel.state.deal.result ?? .init(files: []) : viewModel.state.deal.meta ?? .init(files: []),
                contentType: viewModel.state.uploaderContentType ?? .metadata,
                secretKey: viewModel.state.decryptedKey,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                filesAPIService: try? APIServiceFactory.shared.makeFileService())), action: { actionType in
                    switch actionType {
                    case .close:
                        uploaderState = .hidden
                        viewModel.trigger(.uploaderContentType(nil))

                    case .success(let meta, let contentType):
                        viewModel.trigger(.updateContent(meta, contentType))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            uploaderState = .hidden
                            viewModel.trigger(.uploaderContentType(nil))
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

    private func actionSheetCancelSignButtons() -> [Alert.Button] {
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealCancelSign())) {
                viewModel.trigger(.cancelSign)
            },
            Alert.Button.cancel() {
            }
        ]
    }

    private func actionSheetCancelButtons() -> [Alert.Button] {
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealCancel())) {
                activeModalType = .signTx(.dealCancel)
            },
            Alert.Button.cancel() {
            }
        ]
    }

    private func actionSheetFinishButtons() -> [Alert.Button] {
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealFinish())) {
                activeModalType = .signTx(.dealFinish)
            },
            Alert.Button.cancel() {
            }
        ]
    }

    private func actionSheetEditExecutorButtons() -> [Alert.Button] {
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealExecutorClearAccount())) {
                alertType = .confirmClear
            },
            Alert.Button.default(Text(R.string.localizable.dealExecutorEditAccount())) {
                activeModalType = .editContractor(viewModel.state.executorPublicKey)
            },
            Alert.Button.cancel() {
            }
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
        case .confirmClear:
            return "confirmClear"
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
                    state: DealState(
                        account: Mock.account,
                        availableTokens: Mock.tokenList,
                        tier: .basic,
                        deal: Mock.deal,
                        isSignedByPartner: true
                    ),
                    dealService: nil,
                    transactionSignService: nil,
                    filesAPIService: nil,
                    secretStorage: nil)),
                     availableTokens: [Mock.tokenSOL, Mock.tokenWSOL]) {

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
