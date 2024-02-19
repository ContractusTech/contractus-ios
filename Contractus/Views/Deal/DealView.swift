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
import Shimmer

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
    static let doneStatusImage = Image(systemName: "checkmark.seal.fill")
    static let cancelStatusImage = Image(systemName: "exclamationmark.octagon.fill")
    static let startedStatusImage = Image(systemName: "bolt.fill")
    static let closeImage = Image(systemName: "xmark")
    static let expiredStatusImage = Image(systemName: "calendar.badge.exclamationmark")
}

struct DealView: View {

    enum AlertType {
        case error(String)
        case confirmClear
        case confirmClearChecker
        case confirmRevoke
        case confirmUpdateSignedDeal(() -> Void)
    }

    enum ActionsSheetType: Equatable {
        case confirmCancel
        case dealActions
        case confirmCancelSign
        case confirmFinish
        case executorActions
        case checkerActions
    }
    enum ActiveFullScreenType: Equatable {
        case viewTextDealDetails
        case editTextDealDetails
        case viewTextDealResult
        case editTextDealResult
    }

    enum ActiveModalType: Equatable {
        case editContractor(String?)
        case editChecker(String?)
        case changeAmount
        case changeCheckerAmount
        case changeContractorBond
        case changeOwnerBond
        case importSharedKey
        case filePreview(URL)
        case shareDeal
        case signTx(ContractusAPI.TransactionType)
    }

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hudCoordinator: JGProgressHUDCoordinator

    @StateObject var viewModel: AnyViewModel<DealState, DealInput>
    var callback: () -> Void

    @State private var activeModalType: ActiveModalType?
    @State private var activeFullScreenType: ActiveFullScreenType?
    @State private var alertType: AlertType?
    @State private var actionsType: ActionsSheetType?
    @State private var metaUploaderState: ResizableSheetState = .hidden {
        didSet {
            if metaUploaderState == .hidden {
                switchToMainWindow()
            }
        }
    }
    @State private var resultUploaderState: ResizableSheetState = .hidden {
        didSet {
            if resultUploaderState == .hidden {
                switchToMainWindow()
            }
        }
    }
    @State private var showDeadlinePicker: Bool = false
    @State private var gradientDetails: [Color] = [.clear]
    @State private var gradientResults: [Color] = [.clear]

    var body: some View {
        ScrollView {
            // MARK: - Loading view
            if viewModel.currentMainActions.isEmpty {
                LoadingDealView()
            } else {
                VStack {
                    // MARK: - No secret key
                    notFoundSecretKeyView()
                    dealStatusView()

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
                                        if !viewModel.state.ownerIsClient && viewModel.state.isYouExecutor && viewModel.state.canEditDeal {
                                            CButton(
                                                title: viewModel.state.clientPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(),
                                                style: .secondary,
                                                size: .default,
                                                isLoading: false,
                                                isDisabled: !viewModel.state.canEdit
                                            ) {
                                                EventService.shared.send(event: ExtendedAnalyticsEvent.dealContractorTap(.client))
                                                if viewModel.state.isSignedByPartners {
                                                    alertType = .confirmUpdateSignedDeal {
                                                        activeModalType = .editContractor(viewModel.state.deal.contractorPublicKey)
                                                    }
                                                } else {
                                                    activeModalType = .editContractor(viewModel.state.deal.contractorPublicKey)
                                                }
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
                                                if viewModel.state.deal.amount > 0 {
                                                    Text(viewModel.state.deal.amountFormatted)
                                                        .font(.title)
                                                    Text(viewModel.state.deal.token.code).font(.footnote.weight(.semibold))
                                                        .foregroundColor(R.color.secondaryText.color)
                                                } else {
                                                    Text(R.string.localizable.commonEmpty())
                                                        .font(.title)
                                                }
                                            }
                                        }
                                        Spacer()
                                        if viewModel.state.canEditDeal {
                                            CButton(
                                                title: R.string.localizable.commonEdit(),
                                                style: .secondary,
                                                size: .default,
                                                isLoading: false,
                                                isDisabled: !viewModel.state.canEdit || viewModel.state.currentMainActions.contains(.cancelSign)
                                            ) {
                                                EventService.shared.send(event: DefaultAnalyticsEvent.dealChangeAmountTap)
                                                if viewModel.state.isSignedByPartners {
                                                    alertType = .confirmUpdateSignedDeal {
                                                        activeModalType = .changeAmount
                                                    }
                                                } else {
                                                    activeModalType = .changeAmount
                                                }
                                            }
                                            .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                            .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                                }
                                .padding(14)
                                .background(R.color.secondaryBackground.color)
                                .cornerRadius(20)
                                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                                
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
                                            CButton(
                                                title: viewModel.state.executorPublicKey.isEmpty ? R.string.localizable.commonSet() : R.string.localizable.commonEdit(),
                                                style: .secondary,
                                                size: .default,
                                                isLoading: false,
                                                isDisabled: viewModel.state.currentMainActions.contains(.cancelSign)
                                            ) {
                                                EventService.shared.send(event: ExtendedAnalyticsEvent.dealContractorTap(.executor))
                                                if viewModel.state.isSignedByPartners {
                                                    alertType = .confirmUpdateSignedDeal {
                                                        editExecutor()
                                                    }
                                                } else {
                                                    editExecutor()
                                                }
                                            }
                                            .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                            .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
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
                                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
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
                        
                        // MARK: - Checker
                        if viewModel.state.deal.completionCheckType == .checker {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(R.string.localizable.dealTextChecker())
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)
                                            if viewModel.state.isYouChecker {
                                                Label(text: R.string.localizable.commonYou(), type: .primary)
                                            }
                                        }
                                        HStack {
                                            if viewModel.state.deal.checkerPublicKey?.isEmpty ?? true {
                                                Text(R.string.localizable.commonEmpty())
                                            } else {
                                                Text(ContentMask.mask(from: viewModel.state.deal.checkerPublicKey))
                                            }
                                        }
                                    }
                                    Spacer()
                                    if (viewModel.state.isOwnerDeal || viewModel.state.isYouChecker) && viewModel.state.canEditDeal {
                                        CButton(title: "", icon: Constants.rewardImage, style: .secondary, size: .default, isLoading: false) {
                                            activeModalType = .changeCheckerAmount
                                        }
                                        .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                        .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                    }

                                    if viewModel.state.isOwnerDeal && viewModel.state.canEdit && viewModel.state.canEditDeal {
                                        CButton(
                                            title: R.string.localizable.commonEdit(),
                                            style: .secondary,
                                            size: .default,
                                            isLoading: false
                                        ) {
                                            EventService.shared.send(event: ExtendedAnalyticsEvent.dealContractorTap(.checker))
                                            if viewModel.state.isSignedByPartners {
                                                alertType = .confirmUpdateSignedDeal {
                                                    editChecker()
                                                }
                                            } else {
                                                editChecker()
                                            }
                                        }
                                        .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                        .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                    }
                                }
                                .padding(.bottom, 4)

                                if !(viewModel.state.deal.amountFeeCheckerFormatted ?? "").isEmpty {
                                    HStack(spacing: 6) {
                                        Text(R.string.localizable.dealTextEarning())
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                        Text(viewModel.state.deal.amountFeeCheckerFormatted ?? "")
                                            .font(.footnote)
                                            .foregroundColor(R.color.baseGreen.color)
                                    }
                                    .padding(.bottom, 10)
                                } else {
                                    if viewModel.state.isOwnerDeal {
                                        Text(R.string.localizable.dealTextEarningNotSet())
                                            .font(.footnote)
                                            .foregroundColor(R.color.redText.color)
                                            .padding(.bottom, 10)
                                    }
                                }

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
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
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
                                    Text(R.string.localizable.dealPerformanceBond())
                                        .foregroundColor(R.color.textBase.color)
                                        .font(.title3)
                                    
                                    Text(R.string.localizable.dealPerformanceBondSubtitle())
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
                                                Text(R.string.localizable.dealTextClient())
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
                                                Text(R.string.localizable.dealBondClientSubtitle())
                                                    .font(.footnote)
                                                    .foregroundColor(R.color.secondaryText.color)
                                            }
                                        }
                                        Spacer()
                                        if viewModel.state.canEditDeal {
                                            CButton(
                                                title: R.string.localizable.commonEdit(),
                                                style: .secondary,
                                                size: .default,
                                                isLoading: false,
                                                isDisabled: !(viewModel.state.isOwnerDeal)
                                            ) {
                                                if viewModel.state.isSignedByPartners {
                                                    alertType = .confirmUpdateSignedDeal {
                                                        activeModalType = !viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                                    }
                                                } else {
                                                    activeModalType = !viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                                }
                                            }
                                            .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                            .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
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
                                                Text(R.string.localizable.dealTextExecutor())
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
                                                
                                                Text(R.string.localizable.dealBondExecutorSubtitle())
                                                    .font(.footnote)
                                                    .foregroundColor(R.color.secondaryText.color)
                                            }
                                        }
                                        Spacer()
                                        if viewModel.state.canEditDeal {
                                            CButton(
                                                title: R.string.localizable.commonEdit(),
                                                style: .secondary,
                                                size: .default,
                                                isLoading: false,
                                                isDisabled: false
                                            ) {
                                                if viewModel.state.isSignedByPartners {
                                                    alertType = .confirmUpdateSignedDeal {
                                                        activeModalType = viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                                    }
                                                } else {
                                                    activeModalType = viewModel.state.ownerIsExecutor ? .changeOwnerBond : .changeContractorBond
                                                }
                                            }
                                            .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                            .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                                }
                            }
                            .padding(14)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(20)
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                        }

                        // MARK: - Deadline
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(R.string.localizable.dealTextDeadline())
                                            .font(.footnote.weight(.semibold))
                                            .textCase(.uppercase)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                                            if let deadline = viewModel.state.deal.deadline {
                                                Text(deadline.asDateFormatted())
                                                    .font(.title)
                                                    .foregroundColor(
                                                        deadline > Date() || [.finished, .canceled, .revoked].contains(viewModel.state.deal.status)
                                                        ? R.color.textBase.color
                                                        : R.color.redText.color
                                                    )
                                            } else {
                                                Text(R.string.localizable.commonEmpty())
                                                    .font(.title)
                                            }
                                        }
                                        Text(R.string.localizable.dealBondDeadlineSubtitle())
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                        
                                    }
                                    .popover(isPresented: $showDeadlinePicker) {
                                        DeadlineView(
                                            viewModel: .init(DeadlineViewModel(
                                                deal: viewModel.state.deal,
                                                account: viewModel.state.account,
                                                dealService: try? APIServiceFactory.shared.makeDealsService()
                                            ))
                                        ) { updatedDeal in
                                            viewModel.trigger(.update(updatedDeal)) {
                                                self.callback()
                                            }
                                        }
                                    }
                                }
                                Spacer()
                                if viewModel.state.canEditDeal {
                                    CButton(
                                        title: R.string.localizable.commonEdit(),
                                        style: .secondary,
                                        size: .default,
                                        isLoading: false,
                                        isDisabled: !(viewModel.state.isOwnerDeal)
                                    ) {
                                        if viewModel.state.isSignedByPartners {
                                            alertType = .confirmUpdateSignedDeal {
                                                showDeadlinePicker.toggle()
                                            }
                                        } else {
                                            showDeadlinePicker.toggle()
                                        }
                                    }
                                    .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                        }
                        .padding(14)
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(20)
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                
                HStack {
                    Text(R.string.localizable.dealTextDetails())
                        .font(.title.weight(.regular))

                    if !(viewModel.state.deal.meta?.contentIsEmpty ?? true) && viewModel.state.withEncryption {
                        Label(text: R.string.localizable.commonEncrypted(), type: .default)
                    }

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
                                }
                                
                                Spacer()
                                if viewModel.state.canEditDeal {
                                    CButton(
                                        title: (viewModel.state.deal.meta?.contentIsEmpty ?? true) ? R.string.localizable.commonSet() : R.string.localizable.commonOpen(),
                                        style: .secondary,
                                        size: .default,
                                        isLoading: false,
                                        isDisabled: !viewModel.state.canEdit || viewModel.state.currentMainActions.contains(.cancelSign)
                                    ) {
                                        EventService.shared.send(event: DefaultAnalyticsEvent.dealDescriptionTap)
                                        if viewModel.state.isSignedByPartners {
                                            alertType = .confirmUpdateSignedDeal {
                                                editDetailsText()
                                            }
                                        } else {
                                            editDetailsText()
                                        }
                                    }
                                    .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                } else if viewModel.state.canViewDeal {
                                    CButton(
                                        title: R.string.localizable.commonView(),
                                        style: .secondary,
                                        size: .default,
                                        isLoading: false,
                                        isDisabled: false
                                    ) {
                                        EventService.shared.send(event: DefaultAnalyticsEvent.dealDescriptionTap)
                                        viewDetailsText()
                                    }
                                    .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                }
                            }
                            VStack(alignment: .leading) {
                                if let content = viewModel.state.deal.meta?.content, !content.text.isEmpty {
                                    HStack {
                                        TruncableText(
                                            text: Text(viewModel.state.withEncryption
                                                       ? ContentMask.maskAll(content.text)
                                                       : content.text.fromBase64() ?? "")
                                                  .font(.footnote),
                                            lineLimit: 5,
                                            isTruncatedUpdate: { isTruncated in
                                                if isTruncated {
                                                    gradientDetails = [.clear, .clear, .clear, R.color.secondaryBackground.color]
                                                } else {
                                                    gradientDetails = [.clear]
                                                }
                                            }
                                        )
                                        .overlay {
                                            LinearGradient(colors: gradientDetails, startPoint: .top, endPoint: .bottom)
                                        }
                                        Spacer()
                                    }
                                } else {
                                    HStack {
                                        Text(viewModel.state.withEncryption ? R.string.localizable.dealHintEncryptContent() : R.string.localizable.dealHintNoEncryptContent())
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
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
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
                                    CButton(
                                        title: R.string.localizable.commonAdd(),
                                        style: .secondary,
                                        size: .default,
                                        isLoading: false,
                                        isDisabled: !viewModel.state.canEdit || viewModel.state.currentMainActions.contains(.cancelSign)
                                    ) {
                                        EventService.shared.send(event: DefaultAnalyticsEvent.dealDescriptionAddFileTap)
                                        if viewModel.state.isSignedByPartners {
                                            alertType = .confirmUpdateSignedDeal {
                                                metaUploaderState = .medium
                                            }
                                        } else {
                                            metaUploaderState = .medium
                                        }
                                    }
                                    .opacity(viewModel.state.editIsVisible ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
                                }
                            }
                            VStack(alignment: .leading, spacing: 12) {
                                if viewModel.state.deal.meta?.files.isEmpty ?? true {
                                    HStack {
                                        Text(viewModel.state.withEncryption ? R.string.localizable.dealHintEncryptFiles() : R.string.localizable.dealHintNoEncryptFiles())
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                        Spacer()
                                    }
                                } else {
                                    ForEach(viewModel.state.deal.meta?.files ?? []) { file in
                                        FileItemView(
                                            file: file,
                                            decryptedName: viewModel.state.withEncryption ? viewModel.state.decryptedFiles[file.md5]?.lastPathComponent : file.name,
                                            showDeleteButton: viewModel.state.editIsVisible && viewModel.state.canEditDeal
                                        ) { action in
                                            switch action {
                                            case .open:
                                                viewModel.trigger(.openFile(file))
                                            case .delete:
                                                viewModel.trigger(.deleteMetadataFile(file)) {
                                                    self.callback()
                                                }
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
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                    
                    if viewModel.state.showResult {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(R.string.localizable.dealResultsTitle())
                                    .font(.title.weight(.regular))
                                    .foregroundColor(R.color.textBase.color)

                                if !viewModel.state.deal.resultIsEmpty && viewModel.state.withEncryption {
                                    Label(text: R.string.localizable.commonEncrypted(), type: .default)
                                }
                                
                                Spacer()

                            }
                            Text(R.string.localizable.dealResultsHint())
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                            
                        }
                        .padding(EdgeInsets(top: 20, leading: 12, bottom: 12, trailing: 12))
                        
                        // MARK: - Results
                        VStack {
                            // MARK: - Results text
                            VStack {
                                HStack {
                                    Text(R.string.localizable.dealTextText())
                                        .font(.title3.weight(.regular))
                                    
                                    Spacer()
                                    
                                    if viewModel.state.canSendResult {
                                        CButton(
                                            title: (viewModel.state.deal.result?.contentIsEmpty ?? true) ? R.string.localizable.commonAdd() : R.string.localizable.commonEdit(),
                                            style: .secondary, size: .default,
                                            isLoading: false,
                                            isDisabled: !viewModel.state.canEditResult
                                        ) {
                                            EventService.shared.send(event: DefaultAnalyticsEvent.dealResultTap)
                                            activeFullScreenType = .editTextDealResult
                                        }
                                    } else {
                                        CButton(title: R.string.localizable.commonView(), style: .secondary, size: .default, isLoading: false) {
                                            activeFullScreenType = .viewTextDealResult
                                        }
                                    }
                                }
                                VStack(alignment: .leading) {
                                    if let result = viewModel.state.deal.result?.content, !result.text.isEmpty {
                                        HStack {
                                            TruncableText(
                                                text: Text(viewModel.state.withEncryption
                                                           ? ContentMask.maskAll(result.text)
                                                           : result.text.fromBase64() ?? "")
                                                      .font(.footnote),
                                                lineLimit: 5,
                                                isTruncatedUpdate: { isTruncated in
                                                    if isTruncated {
                                                        gradientResults = [.clear, .clear, .clear, R.color.secondaryBackground.color]
                                                    } else {
                                                        gradientResults = [.clear]
                                                    }
                                                }
                                            )
                                            .overlay {
                                                LinearGradient(colors: gradientResults, startPoint: .top, endPoint: .bottom)
                                            }
                                            Spacer()
                                        }
                                    } else {
                                        HStack {
                                            Text(viewModel.state.withEncryption ? R.string.localizable.dealHintEncryptContent() : R.string.localizable.dealHintNoEncryptContent())
                                                .foregroundColor(R.color.secondaryText.color)
                                                .font(.footnote)
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
                            // MARK: - Results files
                            VStack {
                                HStack {
                                    Text(R.string.localizable.dealTextFiles())
                                        .font(.title3.weight(.regular))
                                    Spacer()
                                    if viewModel.state.canSendResult {
                                        CButton(title: R.string.localizable.commonAdd(), style: .secondary, size: .default, isLoading: false, isDisabled: !viewModel.state.canEditResult) {
                                            EventService.shared.send(event: DefaultAnalyticsEvent.dealResultAddFileTap)
                                            viewModel.trigger(.uploaderContentType(.result))
                                            resultUploaderState = .medium
                                        }
                                    }
                                }
                                VStack(alignment: .leading) {
                                    if viewModel.state.deal.result?.files.isEmpty ?? true {
                                        HStack {
                                            Text(viewModel.state.withEncryption ? R.string.localizable.dealHintEncryptFiles() : R.string.localizable.dealHintNoEncryptFiles())
                                                .foregroundColor(R.color.secondaryText.color)
                                                .font(.footnote)
                                            Spacer()
                                        }
                                    } else {
                                        if let files = viewModel.state.deal.result?.files {
                                            ForEach(files) { file in
                                                FileItemView(
                                                    file: file,
                                                    decryptedName: viewModel.state.withEncryption ?  viewModel.state.decryptedFiles[file.md5]?.lastPathComponent : file.name,
                                                    showDeleteButton: viewModel.state.deal.status == .started && viewModel.state.isYouExecutor
                                                ) { action in
                                                    switch action {
                                                    case .open:
                                                        viewModel.trigger(.openFile(file))
                                                    case .delete:
                                                        viewModel.trigger(.deleteResultFile(file)) {
                                                            self.callback()
                                                        }
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
                        .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                    }
                    // MARK: - Sign Status
                    if viewModel.state.canEditDeal {
                        signStatus()
                    }
                    
                    // MARK: - Actions
                    actionsView()
                }
            }
        }
        .shimmering(active: viewModel.currentMainActions.isEmpty)
        .refreshable(action: {
            await withCheckedContinuation { continuation in
                viewModel.trigger(.update(nil)) {
                    continuation.resume()
                }
            }
        })
        .resizableSheet($metaUploaderState, id: "metaUploader", builder: { builder in
            builder.content { context in
                uploaderView(contentType: .metadata)
            }
            .animation(.easeInOut.speed(1.2))
            .background { context in
                Color.black
                    .opacity(context.state == .medium ? 0.5 : 0)
                    .ignoresSafeArea()
            }
            .supportedState([.medium])
        })
        .resizableSheet($resultUploaderState, id: "resultsUploader", builder: { builder in
            builder.content { context in
                uploaderView(contentType: .result)
            }
            .animation(.easeInOut.speed(1.2))
            .background { context in
                Color.black
                    .opacity(context.state == .medium ? 0.5 : 0)
                    .ignoresSafeArea()
            }
            .supportedState([.medium])
        })
        .fullScreenCover(item: $activeFullScreenType, onDismiss: {
            viewModel.trigger(.sheetClose)
        }, content: { type in
            switch type {
            case .editTextDealDetails, .viewTextDealDetails:
                TextEditorView(
                    allowEdit: type == .editTextDealDetails,
                    mode: type == .editTextDealDetails ? .edit : .view,
                    viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(
                        dealId: viewModel.state.deal.id,
                        tier: viewModel.state.tier,
                        content: viewModel.state.deal.meta ?? .init(files: []),
                        contentType: .metadata,
                        secretKey: viewModel.state.decryptedKey,
                        dealService: try? APIServiceFactory.shared.makeDealsService())),
                    action: { result in
                        switch result {
                        case .close:
                            activeFullScreenType = nil
                        case .success(let meta):
                            viewModel.trigger(.updateContent(meta, .metadata)) {
                                self.callback()
                            }
                        }
                    })
            case .editTextDealResult, .viewTextDealResult:
                TextEditorView(
                    allowEdit: type == .editTextDealResult,
                    mode: type == .editTextDealResult ? .edit : .view,
                    viewModel: AnyViewModel<TextEditorState, TextEditorInput>(TextEditorViewModel(
                        dealId: viewModel.state.deal.id,
                        tier: viewModel.state.tier,
                        content: viewModel.state.deal.result ?? .init(files: []),
                        contentType: .result,
                        secretKey: viewModel.state.decryptedKey,
                        dealService: try? APIServiceFactory.shared.makeDealsService())),
                    action: { result in
                        switch result {
                        case .close:
                            activeFullScreenType = nil
                        case .success(let meta):
                            viewModel.trigger(.updateContent(meta, .result)) {
                                self.callback()
                            }
                        }
                    })
            }
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
                    didChange: { newAmount, typeAmount, allowHolderMode in
                        switch typeAmount {
                        case .deal:
                            viewModel.trigger(.changeAmount(newAmount, allowHolderMode)) {
                                self.callback()
                            }
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
                    didChange: { newAmount, typeAmount, allowHolderMode in
                        switch typeAmount {
                        case .deal:
                            viewModel.trigger(.changeAmount(newAmount, allowHolderMode)) {
                                self.callback()
                            }
                        case .checker:
                            viewModel.trigger(.changeCheckerAmount(newAmount)) {
                                self.callback()
                            }
                        case .ownerBond:
                            viewModel.trigger(.changeOwnerBondAmount(newAmount)) {
                                self.callback()
                            }
                        case .contractorBond:
                            viewModel.trigger(.changeContractorBondAmount(newAmount)) {
                                self.callback()
                            }
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
                    viewModel.trigger(.update(deal)) {
                        self.callback()
                    }
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
                    viewModel.trigger(.update(deal)) {
                        self.callback()
                    }
                }
                .interactiveDismiss(canDismissSheet: false)
            case .filePreview(let url):
                QuickLookView(url: url) {

                }
            case .shareDeal:
                if let shareData = viewModel.state.shareDeal {
                    ShareContentView(
                        contentType: .privateKey,
                        informationType: .none,
                        content: shareData,
                        topTitle: R.string.localizable.commonShare(),
                        title: R.string.localizable.shareContentTitleDeal(),
                        subTitle: R.string.localizable.shareContentSubtitleDeal())
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
                        viewModel.trigger(.deleteContractor(.contractor)) {
                            self.callback()
                        }
                    }
                )
            case .confirmClearChecker:
                return Alert(
                    title: Text(R.string.localizable.dealExecutorClearAccount()),
                    message: Text(R.string.localizable.dealExecutorClearAccountMessage()),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text(R.string.localizable.dealExecutorClearAccountConfirm())) {
                        viewModel.trigger(.deleteContractor(.checker)) {
                            self.callback()
                        }
                    }
                )
            case .confirmRevoke:
                return Alert(
                    title: Text(R.string.localizable.commonConfirm()),
                    message: Text(R.string.localizable.dealRevokeMessage()),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text(R.string.localizable.dealRevokeActionsConfirm())) {
                        viewModel.trigger(.cancel) {
                            EventService.shared.send(event: DefaultAnalyticsEvent.dealRevokeTap)
                            self.callback()
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            case .confirmUpdateSignedDeal(let action):
                return Alert(
                    title: Text(R.string.localizable.dealEditWarningTitle()),
                    message: Text(R.string.localizable.dealEditWarning()),
                    primaryButton: .cancel(),
                    secondaryButton: .default(Text(R.string.localizable.commonEdit())) {
                        action()
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
            case .checkerActions:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetEditCheckerButtons())
            }
        })
        .onAppear {
            EventService.shared.send(event: DefaultAnalyticsEvent.dealOpen)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }
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
    private func signStatus() -> some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        R.image.iconDealClient.image
                            .padding(.top, 4)
                        Text(R.string.localizable.dealTextClient())
                            .font(.caption.weight(.bold))
                        Text(viewModel.state.action.signedByOwner ?? false
                             ? R.string.localizable.dealSigned()
                             : R.string.localizable.dealNoSignature()
                        )
                        .font(.caption2)
                        .foregroundColor(viewModel.state.action.signedByOwner ?? false ? R.color.baseGreen.color : R.color.secondaryText.color)
                    }
                    .padding(.vertical, 10)
                    Spacer()
                }
                if viewModel.state.youIsClient {
                    Text(R.string.localizable.commonYou())
                        .font(.caption2)
                        .foregroundColor(R.color.secondaryText.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            Divider().foregroundColor(R.color.baseSeparator.color)
            
            ZStack(alignment: .topTrailing) {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        R.image.iconDealExecutor.image
                            .padding(.top, 4)
                        Text(R.string.localizable.dealTextExecutor())
                            .font(.caption.weight(.bold))
                        Text(viewModel.state.action.signedByContractor ?? false
                             ? R.string.localizable.dealSigned()
                             : R.string.localizable.dealNoSignature()
                        )
                        .font(.caption2)
                        .foregroundColor(viewModel.state.action.signedByContractor ?? false ? R.color.baseGreen.color : R.color.secondaryText.color)
                    }
                    .padding(.vertical, 10)
                    Spacer()
                }
                if viewModel.state.isYouExecutor {
                    Text(R.string.localizable.commonYou())
                        .font(.caption2)
                        .foregroundColor(R.color.secondaryText.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            if viewModel.state.deal.completionCheckType == .checker {
                Divider().foregroundColor(R.color.baseSeparator.color)
                ZStack(alignment: .topTrailing) {
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            R.image.iconDealChecker.image
                                .padding(.top, 4)
                            Text(R.string.localizable.dealTextChecker())
                                .font(.caption.weight(.bold))
                            Text(viewModel.state.action.signedByChecker ?? false
                                 ? R.string.localizable.dealSigned()
                                 : R.string.localizable.dealNoSignature()
                            )
                            .font(.caption2)
                            .foregroundColor(viewModel.state.action.signedByChecker ?? false ? R.color.baseGreen.color : R.color.secondaryText.color)
                        }
                        .padding(.vertical, 10)
                        Spacer()
                    }
                    if viewModel.state.isYouChecker {
                        Text(R.string.localizable.commonYou())
                            .font(.caption2)
                            .foregroundColor(R.color.secondaryText.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .stroke()
                .fill(R.color.baseSeparator.color)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func actionsView() -> some View {
        VStack {
            VStack(alignment: .center, spacing: 16) {
                if viewModel.state.displayInformationForSign {
                    VStack(spacing: 8) {
                        CButton(title: R.string.localizable.dealButtonsSign(), style: .primary, size: .large, isLoading: false, isDisabled: true) { }
                        Text(R.string.localizable.dealInformationAboutSign(viewModel.account.blockchain.title))
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundColor(R.color.textBase.color)
                    }

                }
                ForEach(viewModel.state.currentMainActions) { actionType in
                    switch actionType {
                    case .none:
                        EmptyView()
                    case .sign:
                        VStack(spacing: 8) {
                            if viewModel.state.isSignedByPartners {
                                CButton(title: R.string.localizable.dealButtonsSignAndStart(), style: .primary, size: .large, isLoading: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.dealSignTap)
                                    activeModalType = .signTx(.dealInit)
                                }
                                Text(R.string.localizable.dealDescriptionCommandPartnerAlreadySigned())
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(R.color.secondaryText.color)
                            } else {
                                CButton(title: R.string.localizable.dealButtonsSign(), style: .primary, size: .large, isLoading: false, isDisabled: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.dealSignTap)
                                    activeModalType = .signTx(.dealInit)
                                }
                                Text(R.string.localizable.dealDescriptionCommandFirstSign())
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                        }

                    case .cancelSign:
                        VStack(spacing: 8) {
                            CButton(title: R.string.localizable.dealButtonsCancelSign(), style: .cancel, size: .large, isLoading: false) {
                                actionsType = .confirmCancelSign
                            }
                            Text(R.string.localizable.dealDescriptionCommandCancelSign())
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                    case .cancelDeal:
                        VStack(spacing: 8) {
                            CButton(title: R.string.localizable.dealButtonsCancelDeal(), style: .cancel, size: .large, isLoading: false) {
                                actionsType = .confirmCancel
                            }
                            Text(R.string.localizable.dealDescriptionCommandStopDeal())
                                .font(.footnote)
                                .foregroundColor(R.color.redText.color)
                        }
                    case .finishDeal:
                        VStack(spacing: 8) {
                            CButton(title: R.string.localizable.dealButtonsFinishDeal(), style: .primary, size: .large, isLoading: false, isDisabled: false) {
                                actionsType = .confirmFinish
                            }
                            Text(R.string.localizable.dealDescriptionCommandFinishDeal())
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                    case .waiting:
                        VStack(spacing: 8) {
                            CButton(title: R.string.localizable.dealStatusProcessing(), style: .primary, size: .large, isLoading: true, isDisabled: true) { }
                        }

                    case .revoke:
                        VStack(spacing: 8) {
                            CButton(title: R.string.localizable.dealButtonsCancelDeal(), style: .secondaryCancel, size: .large, isLoading: false) {

                                alertType = .confirmRevoke

                            }
                        }
                    }
                }

            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20))
        .animation(Animation.easeInOut(duration: 0.1), value: viewModel.state.editIsVisible)
    }

    @ViewBuilder
    private func uploaderView(contentType: DealsService.ContentType?) -> some View {
        UploadFileView(
            viewModel: AnyViewModel<UploadFileState, UploadFileInput>(UploadFileViewModel(
                dealId: viewModel.state.deal.id,
                content: contentType == .result
                    ? viewModel.state.deal.result ?? .init(files: [])
                    : viewModel.state.deal.meta ?? .init(files: []),
                contentType: contentType ?? .metadata,
                secretKey: viewModel.state.decryptedKey,
                dealService: try? APIServiceFactory.shared.makeDealsService(),
                filesAPIService: try? APIServiceFactory.shared.makeFileService())), action: { actionType in
                    switch actionType {
                    case .close:
                        metaUploaderState = .hidden
                        resultUploaderState = .hidden
                    case .success(let meta, let contentType):
                        viewModel.trigger(.updateContent(meta, contentType)) {
                            self.callback()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            metaUploaderState = .hidden
                            resultUploaderState = .hidden
                        })
                    }
                }
        )
        .padding(16)
    }

    @ViewBuilder
    func dealStatusImageView() -> some View {
        switch viewModel.state.deal.status {
        case .finished:
            Constants.doneStatusImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(R.color.baseGreen.color)
        case .canceled, .revoked:
            Constants.cancelStatusImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(R.color.secondaryText.color)
        case .started:
            if let deadline = viewModel.state.deal.deadline, deadline < Date() {
                Constants.expiredStatusImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(R.color.yellow.color)
            } else {
                Constants.startedStatusImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(R.color.blue.color)
            }
        case .finishing, .canceling, .starting:
            EmptyView()

        case .unknown, .new:
            EmptyView()
        }
    }
    @ViewBuilder
    func notFoundSecretKeyView() -> some View {
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
            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func dealStatusView() -> some View {

        switch viewModel.state.deal.status {
        case .finished, .canceled, .revoked, .started:
            if let deadline = viewModel.state.deal.deadline, deadline < Date(),
               !viewModel.currentMainActions.contains(.cancelDeal) {
                EmptyView()
            } else {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            dealStatusImageView()
                            
                            Text(statusTitle())
                                .font(.body.weight(.bold))
                                .foregroundColor(R.color.textBase.color)
                            Text(statusSubtitle())
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                }
            }
        case .finishing, .canceling, .starting:
            EmptyView()

        case .unknown, .new:
            EmptyView()
        }
    }

    private func statusTitle() -> String {
        if let deadline = viewModel.state.deal.deadline, deadline < Date() && viewModel.state.deal.status == .started {
            return R.string.localizable.dealStatusExpiredTitle()
        }

        if viewModel.state.deal.status == .finished {
            return R.string.localizable.dealStatusFinishedTitle()
        }

        if viewModel.state.deal.status == .started {
            return R.string.localizable.dealStatusStartedTitle()
        }
        return R.string.localizable.dealStatusCanceledTitle()
    }

    private func statusSubtitle() -> String {
        if let deadline = viewModel.state.deal.deadline, deadline < Date() && viewModel.state.deal.status == .started {
            return R.string.localizable.dealStatusExpiredSubtitle()
        }
        if viewModel.state.deal.status == .started {
            if viewModel.isYouExecutor {
                return R.string.localizable.dealStatusStartedSubtitleExecutor(Date.fullRelativeDateFormatted(from: Date(), to: viewModel.deal.deadline))
            }

            if viewModel.isYouChecker {
                return R.string.localizable.dealStatusStartedSubtitleChecker()
            }

            return R.string.localizable.dealStatusStartedSubtitleClient(Date.fullRelativeDateFormatted(from: Date(), to: viewModel.deal.deadline))

        }
        if viewModel.state.deal.status == .revoked {
            return R.string.localizable.dealStatusRevokedSubtitle()
        }
        if viewModel.state.deal.status == .canceled {
            return R.string.localizable.dealStatusCanceledSubtitle()
        }
        if viewModel.state.checkerIsEmpty {
            return R.string.localizable.dealStatusFinishedSubtitle(viewModel.deal.amountFormattedWithCode, ContentMask.mask(from: viewModel.executorPublicKey))

        }
        return R.string.localizable.dealStatusFinishedSubtitleWithChecker(viewModel.deal.amountFormattedWithCode, ContentMask.mask(from: viewModel.executorPublicKey), viewModel.deal.amountFeeCheckerFormatted ?? "", ContentMask.mask(from: viewModel.state.deal.checkerPublicKey ?? ""))
    }

    private func actionSheetMenuButtons() -> [Alert.Button] {
        if viewModel.isOwnerDeal {
            return [
                Alert.Button.default(Text(viewModel.state.hasSecretKey ?  R.string.localizable.dealShareDeal() : R.string.localizable.dealShareSecretKey())) {
                    activeModalType = .shareDeal
                },
                Alert.Button.cancel() {

                }]
        }
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealTextDecline())) {
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

    private func actionSheetEditCheckerButtons() -> [Alert.Button] {
        return [
            Alert.Button.destructive(Text(R.string.localizable.dealExecutorClearAccount())) {
                alertType = .confirmClearChecker
            },
            Alert.Button.default(Text(R.string.localizable.dealExecutorEditAccount())) {
                activeModalType = .editChecker(viewModel.state.deal.checkerPublicKey)
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
            hud.textLabel.text = R.string.localizable.commonDownloading()
            hud.indicatorView = JGProgressHUDPieIndicatorView()
            hud.progress = Float(progress)
            hud.cancelPressedAction = {
                ImpactGenerator.light()
                viewModel.trigger(.cancelDownload)
                hud.dismiss()
            }
            return hud
        }
    }

    private func decryptingHUD() {
        let text = R.string.localizable.commonDecrypting()
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
    
    private func editExecutor() {
        if viewModel.state.executorPublicKey.isEmpty {
            activeModalType = .editContractor(viewModel.state.executorPublicKey)
        } else {
            actionsType = .executorActions
        }
    }
    
    private func editChecker() {
        if viewModel.state.deal.checkerPublicKey?.isEmpty ?? true {
            activeModalType = .editChecker(viewModel.state.deal.checkerPublicKey)
        } else {
            actionsType = .checkerActions
        }
    }
    
    private func editDetailsText() {
        if self.viewModel.isYouChecker && !self.viewModel.state.isOwnerDeal {
            activeFullScreenType = .viewTextDealDetails
        } else {
            activeFullScreenType = .editTextDealDetails
        }
    }

    private func viewDetailsText() {
        activeFullScreenType = .viewTextDealDetails
    }
}

struct LoadingDealView: View {

    var body: some View {
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
                                    Label(text: R.string.localizable.commonYou(), type: .primary)
                                        .opacity(0)
                                }
                                Text(R.string.localizable.commonEmpty())
                                    .opacity(0)
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

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
                                Text(R.string.localizable.commonEmpty())
                                    .font(.title)
                                    .opacity(0)
                            }
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    }
                    .padding(14)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                    // MARK: - Executor
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(R.string.localizable.dealTextExecutor())
                                        .font(.footnote.weight(.semibold))
                                        .textCase(.uppercase)
                                        .foregroundColor(R.color.secondaryText.color)
                                }
                                Text(R.string.localizable.commonEmpty())
                                    .opacity(0)
                            }
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))

                        Text(R.string.localizable.dealHintAboutExecutor())
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                            .opacity(0)
                    }
                    .padding(14)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(20)
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
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
        }
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
    }
}

struct FileItemView: View {

    enum ActionType {
        case open, delete
    }
    var file: MetadataFile
    var decryptedName: String?
    var showDeleteButton: Bool = true
    var action: (Self.ActionType) -> Void

    @State private var confirmPresented: Bool = false
    
    var body: some View {
        VStack {
            Divider()
                .foregroundColor(R.color.baseSeparator.color.opacity(0.2))
            HStack(alignment: .center, spacing: 6) {
                Button {
                    action(.open)
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        if let decryptedName = decryptedName {
                            ZStack {
                                Circle()
                                    .fill(R.color.mainBackground.color)
                                    .frame(width: 32, height: 32)
                                decryptedName.imageByFileName
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(R.color.mainBackground.color)
                                    .frame(width: 32, height: 32)
                                Constants.lockFile
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(decryptedName ?? ContentMask.maskContent())
                                .lineLimit(1)
                                .font(.callout.weight(.medium))
                                .foregroundColor(R.color.textBase.color)
                                .truncationMode(.middle)

                            HStack(spacing: 12) {
                                Text(FileSizeFormatter.shared.format(file.size))
                                    .multilineTextAlignment(.leading)
                                    .font(.footnote.weight(.medium))
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                            .frame(height: 14)
                        }
                    }
                }

                Spacer()
                if showDeleteButton {
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
            }
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
        .confirmationDialog("", isPresented: $confirmPresented) {
            Button(R.string.localizable.dealDeleteAlertButton(), role: .destructive) {
                action(.delete)
            }
        } message: {
            Text(R.string.localizable.dealDeleteAlertMessage())
        }
    }
}


extension DealView.ActiveModalType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

extension DealView.ActiveFullScreenType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

extension DealView.AlertType: Identifiable {
    var id: String {
        return "\(self)"
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
                        tier: .basic,
                        deal: Mock.deal,
                        isSignedByPartners: true
                    ),
                    dealService: nil,
                    transactionSignService: nil,
                    filesAPIService: nil,
                    secretStorage: nil))
            ) {

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
