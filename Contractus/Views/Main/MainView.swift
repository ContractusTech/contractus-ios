//
//  MainView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.07.2022.
//

import SwiftUI
import SolanaSwift
import ResizableSheet
import SwiftUIPullToRefresh
import ContractusAPI 

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
    static let arrowDownImage = Image(systemName: "chevron.down")
    static let plusImage = Image(systemName: "plus")
    static let menuImage = Image(systemName: "gearshape")
    static let qrCode = Image(systemName: "qrcode")
    static let infoImage = Image(systemName: "info.circle.fill")
    static let crowImage = Image(systemName: "crown.fill")
    static let scanQRImage = Image(systemName: "qrcode.viewfinder")
    static let columns: [GridItem] = {
        return [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]
    }()
}

struct MainView: View {

    enum SheetType {
        case newDeal, menu, qrScan, sharePublicKey, wrap(from: Amount, to: Amount), webView(URL), topUp(URL), tokenSettings
    }

    @StateObject var viewModel: AnyViewModel<MainState, MainInput>
    var logoutCompletion: () -> Void
    
    @State private var selectedDeal: Deal?
    @State private var sheetType: SheetType? = .none
    @State private var dealsType: MainViewModel.State.DealType = .all
    @State private var transactionSignType: TransactionSignType?
    @State private var topUpState: ResizableSheetState = .hidden {
        didSet {
            if topUpState == .hidden {
                switchToMainWindow()
            }
        }
    }
    @State private var holderModeState: ResizableSheetState = .hidden {
        didSet {
            if holderModeState == .hidden {
                switchToMainWindow()
            }
        }
    }
    @State private var showChangelog: Bool = false
    @State private var showBuyCtus: Bool = false
    @State private var showDealFilter: Bool = false
    
    var body: some View {

        JGProgressHUDPresenter(userInteractionOnHUD: true) {
            NavigationView {
                ScrollView {
                    VStack {
                        BalanceView(
                            state: viewModel.state.balance != nil ? .loaded(.init(balance: viewModel.state.balance!)) : .empty,
                            topUpAction: {
                                EventService.shared.send(event: DefaultAnalyticsEvent.mainTopupTap)
                                topUpState = .medium
                                ImpactGenerator.soft()
                            }, infoAction: {
                                sheetType = .webView(AppConfig.ctusInfoURL)
                            }, swapAction: { fromAmount, toAmount in
                                sheetType = .wrap(from: fromAmount, to: toAmount)
                            }) {
                                sheetType = .tokenSettings
                            }

                        UnlockHolderButtonView() {
                            EventService.shared.send(event: DefaultAnalyticsEvent.buyformOpen)
                            holderModeState = .medium
                        }

                        if !viewModel.state.statistics.isEmpty {
                            StatisticsView(items: viewModel.state.statistics) { item in
                                if item.type == .locked {
                                    sheetType = .webView(AppConfig.faqURL)
                                }
                            }
                        }

                        HStack(alignment: .center, spacing: 0) {
                            VStack {
                                Button {
                                    showDealFilter.toggle()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(dealTitle(type: dealsType))
                                            .font(.title2.weight(.medium))
                                            .foregroundColor(R.color.textBase.color)
                                        HStack {
                                            Constants.arrowDownImage
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 12, height: 12)
                                                .foregroundColor(R.color.secondaryText.color)
                                        }.padding(.top, 4)
                                    }
                                }
                            }
                            Spacer()

                            CButton(
                                title: "",
                                icon: Constants.qrCode,
                                style: .clear,
                                size: .default,
                                isLoading: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.mainAccountAddressTap)
                                    sheetType = .sharePublicKey
                                }
                            Rectangle()
                                .frame(width: 8)
                                .foregroundColor(Color.clear)

                            CButton(
                                title: R.string.localizable.mainTitleNewDeal(),
                                icon: Constants.plusImage,
                                style: .primary,
                                size: .default,
                                isLoading: false) {
                                    EventService.shared.send(event: DefaultAnalyticsEvent.mainNewDealTap)
                                    sheetType = .newDeal
                                }
                        }
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))

                        switch viewModel.state.dealsState {
                        case .loaded:
                            if viewModel.deals.isEmpty {
                                VStack(alignment: .center) {

                                    VStack(spacing: 4) {
                                        R.image.emptyDeals.image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)

                                        VStack(spacing: 12) {
                                            Text(R.string.localizable.mainEmptyTitle())
                                                .font(.title3.weight(.semibold))
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(R.color.secondaryText.color.opacity(0.5))
                                            Text(R.string.localizable.mainEmptyMessage())
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(R.color.secondaryText.color.opacity(0.5))
                                        }
                                        .padding(.leading, 40)
                                        .padding(.trailing, 40)
                                        .padding(.bottom, 40)

                                    }
                                }
                                .padding(10)
                            } else {
                                LazyVGrid(columns: Constants.columns, spacing: 4) {
                                    ForEach(viewModel.deals, id: \.id) { item in
                                        Button {
                                            selectedDeal = item
                                            EventService.shared.send(event: DefaultAnalyticsEvent.mainDealTap)
                                        } label: {
                                            DealItemView(
                                                amountFormatted: item.amountFormattedShort,
                                                tokenSymbol: item.token.code,
                                                withPublicKey: item.getPartnersBy(viewModel.state.account.publicKey),
                                                status: item.status,
                                                roleType: dealRole(deal: item),
                                                timeSinceCreated: item.createdAt.relativeDateFormatted,
                                                checkerAmount: item.amountFeeCheckerFormatted)
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 42, trailing: 8))
                            }

                        case .loading:
                            HStack(alignment: .center) {
                                ProgressView()
                            }
                            .padding(50)
                        }
                    }
                }.refreshableCompat(loadingViewBackgroundColor: .clear, onRefresh: { done in
                    viewModel.trigger(.load(dealsType)) {
                        done()
                    }
                }, progress: { state in
                    RefreshActivityIndicator(isAnimating: state == .loading) {
                        $0.hidesWhenStopped = false
                    }
                })
                .onChange(of: dealsType, perform: { newType in
                    viewModel.trigger(.load(newType))
                })
                .confirmationDialog(Text(R.string.localizable.mainTitleFilter()), isPresented: $showDealFilter, actions: {
                    ForEach(MainViewModel.State.DealType.allCases, id: \.self) { type in
                        Button(dealTitle(type: type), role: .none) {
                            dealsType = type
                        }
                    }
                })
                .resizableSheet($topUpState, id: "topUp", builder: { builder in
                    builder.content { context in
                        TopUpView { type in
                            switch type {
                            case .crypto:
                                sheetType = .sharePublicKey
                                topUpState = .hidden
                            case .fiat(let url):
                                sheetType = .topUp(url)
                                topUpState = .hidden
                            case .loan:
                                break;
                            }
                        }
                    }
                    .animation(.easeInOut)
                    .background { context in
                        Color.black
                            .opacity(context.state == .medium ? 0.5 : 0)
                            .ignoresSafeArea()
                            .onTapGesture(perform: {
                                topUpState = .hidden
                            })
                    }
                    .supportedState([.medium, .hidden])
                })
                .resizableSheet($holderModeState, id: "holderMode") { builder in
                    builder.content { context in
                        UnlockHolderView { type in
                            switch type {
                            case .buy:
                                EventService.shared.send(event: DefaultAnalyticsEvent.buyformBuyTap)
                                holderModeState = .hidden
                                showBuyCtus.toggle()
                            case .coinstore:
                                holderModeState = .hidden
                                openCoinstore()
                            case .raydium:
                                holderModeState = .hidden
                                openRaydium()
                            case .pancake:
                                holderModeState = .hidden
                                openPancake()
                            }
                        }
                    }
                    .animation(.easeInOut)
                    .background { context in
                        Color.black
                            .opacity(context.state == .medium ? 0.5 : 0)
                            .ignoresSafeArea()
                            .onTapGesture(perform: {
                                holderModeState = .hidden
                            })
                    }
                    .supportedState([.medium, .hidden])
                }

                .sheet(item: $sheetType, content: { type in
                    switch type {
                    case .tokenSettings:
                        TokenSelectView(viewModel: .init(TokenSelectViewModel(
                            allowHolderMode: true,
                            mode: .many,
                            tier: viewModel.state.balance?.tier ?? .basic,
                            selectedTokens: viewModel.state.selectedTokens,
                            disableUnselectTokens: viewModel.state.disableUnselectTokens,
                            resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService())
                        )) { result in
                            switch result {
                            case .many(let tokens):
                                viewModel.trigger(.saveTokenSettings(tokens))
                            case .none, .single:
                                break
                            }
                            sheetType = nil
                        }
                    case .topUp(let url):
                        NavigationView {
                            WebView(url: url)
                                .edgesIgnoringSafeArea(.bottom)
                                .navigationBarItems(
                                    trailing: Button(action: {
                                        sheetType = nil
                                    }, label: {
                                        Constants.closeImage
                                            .resizable()
                                            .frame(width: 21, height: 21)
                                            .foregroundColor(R.color.textBase.color)
                                    }))
                                .navigationTitle(R.string.localizable.commonTopUp())
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .baseBackground()
                        .interactiveDismiss(canDismissSheet: false)
                    case .webView(let url):
                        NavigationView {
                            WebView(url: url)
                                .edgesIgnoringSafeArea(.bottom)
                                .navigationBarItems(
                                    trailing: Button(R.string.localizable.commonClose(), action: {
                                    sheetType = nil
                                }))
                                .navigationTitle(R.string.localizable.mainAboutTiers())
                                .navigationBarTitleDisplayMode(.inline)
                        }.baseBackground()

                    case .wrap(let from, let to):
                        wrapView(amountNativeToken: from, amountWrapToken: to)
                    case .newDeal:
                        CreateDealView(
                            viewModel: AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(
                                account: viewModel.state.account,
                                accountAPIService: try? APIServiceFactory.shared.makeAccountService(),
                                dealsAPIService: try? APIServiceFactory.shared.makeDealsService()))) { deal in
                                    selectedDeal = deal
                                    viewModel.trigger(.load(dealsType))
                                }
                                .interactiveDismiss(canDismissSheet: false)
                    case .menu:
                        MenuView { action in
                            switch action {
                            case .changeAccount:
                                viewModel.trigger(.updateAccount) {
                                    load()
                                }

                            case .logout:
                                logoutCompletion()
                            }
                        }
                    case .qrScan:
                        QRCodeScannerView(configuration: .scannerAndInput, blockchain: viewModel.state.account.blockchain) { result in
                            viewModel.trigger(.executeScanResult(result))
                        }
                    case .sharePublicKey:
                        // TODO: - Refactor
                        if let shareData = try? SharablePublicKey(shareContent: viewModel.state.account.publicKey) {
                            ShareContentView(
                                content: shareData,
                                topTitle: R.string.localizable.commonAccount(),
                                title: R.string.localizable.commonYouAccount(),
                                subTitle: R.string.localizable.shareContentSubtitle()) { _ in

                            } dismissAction: {
                                sheetType = .none
                            }
                        } else {
                            EmptyView()
                        }
                    }
                })
                .fullScreenCover(isPresented: $showChangelog) {
                    let service = ServiceFactory.shared.makeOnboardingService()
                    OnboardingView(viewModel: AnyViewModel<OnboardingState, OnboardingInput>(OnboardingViewModel(
                        contentType: .changelog,
                        state: OnboardingState(state: .none, errorState: .none),
                        onboardingService: service))
                    ) {
                        showChangelog.toggle()
                        EventService.shared.send(event: ExtendedAnalyticsEvent.changelogClose(service.changelogId()))
                    }
                }
                .fullScreenCover(isPresented: $showBuyCtus) {
                    let service = APIServiceFactory.shared.makeCheckoutService()
                    BuyTokensView(
                        viewModel: AnyViewModel<BuyTokensState, BuyTokensInput>(BuyTokensViewModel(
                            account: viewModel.state.account,
                            checkoutService: service)
                        )
                    )
                }
                .navigationDestination(for: $selectedDeal) { deal in
                    dealView(deal: deal)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Button {
                            if let tier = viewModel.state.balance?.tier {
                                EventService.shared.send(event: ExtendedAnalyticsEvent.mainTiersTap(tier))
                            }
                            sheetType = .webView(AppConfig.tiersInformationURL)
                        } label: {
                            VStack(alignment: .center, spacing: 3) {
                                tierLabel(viewModel.state.balance?.tier)

                                HStack(spacing: 2) {
                                    Text(ContentMask.mask(from: viewModel.state.account.publicKey))
                                        .font(.caption2)
                                        .foregroundColor(R.color.secondaryText.color)

                                    if AppConfig.serverType.isDevelop {
                                        Text("•")
                                            .font(.caption2)
                                            .foregroundColor(R.color.secondaryText.color)
                                        Text(AppConfig.serverType.networkTitle)
                                            .font(.caption2)
                                            .foregroundColor(R.color.textWarn.color)
                                    }
                                }

                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            EventService.shared.send(event: DefaultAnalyticsEvent.mainSettingsTap)
                            sheetType = .menu
                        } label: {
                            Constants.menuImage
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            EventService.shared.send(event: DefaultAnalyticsEvent.mainQRscannerTap)
                            sheetType = .qrScan
                        } label: {
                            Constants.scanQRImage
                        }
                    }
                }
                .baseBackground()
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear{
                EventService.shared.send(event: DefaultAnalyticsEvent.mainOpen)
                load()
                let service = ServiceFactory.shared.makeOnboardingService()
                if service.needShowChangelog() {
                    showChangelog = true
                    EventService.shared.send(event: ExtendedAnalyticsEvent.changelogOpen(service.changelogId()))
                }
            }
        }
    }

    @ViewBuilder
    func dealView(deal: Deal) -> some View {
        DealView(viewModel: AnyViewModel<DealState, DealInput>(DealViewModel(
            state: DealState(account: viewModel.account, tier: viewModel.balance?.tier ?? .basic, deal: deal),
            dealService: try? APIServiceFactory.shared.makeDealsService(),
            transactionSignService: ServiceFactory.shared.makeTransactionSign(),
            filesAPIService: try? APIServiceFactory.shared.makeFileService(),
            secretStorage: SharedSecretStorageImpl()))) {
                viewModel.trigger(.load(dealsType))
            }
    }

    @ViewBuilder
    func wrapView(amountNativeToken: Amount, amountWrapToken: Amount) -> some View {

        WrapTokenView(viewModel: AnyViewModel<WrapTokenState, WrapTokenInput>(WrapTokenViewModel(state: .init(account: viewModel.account, amountNativeToken: amountNativeToken, amountWrapToken: amountWrapToken), transactionsService: (try? APIServiceFactory.shared.makeTransactionsService()))))
    }

    private func dealRole(deal: Deal) -> DealItemView.DealRoleType {        
        if (deal.ownerRole == .client && deal.contractorPublicKey == viewModel.state.account.publicKey) ||
            (deal.ownerPublicKey == viewModel.state.account.publicKey && deal.ownerRole == .executor) {
            return .receive
        }

        if deal.checkerPublicKey == viewModel.state.account.publicKey
            && deal.ownerPublicKey != viewModel.state.account.publicKey {
            return .checker
        }
        return .pay
    }

    private func dealTitle(type: MainViewModel.State.DealType) -> String {
        switch type {
        case .all:
            return "Recent"
        case .isChecker:
            return "For checking"
        case .isClient:
            return "As client"
        case .isExecutor:
            return "For execute"
        case .isWorking:
            return "Working"
        case .isDone:
            return "Done"
        case .isCanceled:
            return "Canceled"
        }
    }

    private func load() {
        viewModel.trigger(.preload)
        viewModel.trigger(.load(dealsType))
    }

    @ViewBuilder
    func tierLabel(_ tier: Balance.Tier?) -> some View {
        if let tier = tier {
            HStack(spacing: 5) {
                if tier == .holder {
                    Constants.crowImage
                        .resizable()
                        .frame(width: 9, height: 9)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(tier.textColor)
                }
                Text("\(tier.title)")
                    .font(.caption2.bold())
                    .foregroundColor(tier.textColor)
            }
            .padding(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
            .background(tier.backgroundColor)
            .cornerRadius(10)
            .shadow(radius: 0.3)
        } else {
            HStack(spacing: 5) {
                Text(" ")
                    .font(.footnote.bold())
                    .foregroundColor(R.color.white.color)
                    .frame(width: 62, height: 14)

            }
            .padding(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
            .background(R.color.secondaryBackground.color)
            .cornerRadius(10)
        }

    }
}

fileprivate extension Balance.Tier {
    var backgroundColor: Color {
        switch self {
        case .basic:
            return R.color.white.color
        case .holder:
            return R.color.blue.color
        }
    }
    var textColor: Color {
        switch self {
        case .basic:
            return R.color.black.color
        case .holder:
            return R.color.white.color
        }
    }

    var title: String {
        switch self {
        case .holder:
            return "Holder mode"
        case .basic:
            return "Basic mode"
        }
    }
}


extension MainView.SheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

// MARK: - Previews

#if DEBUG
import ContractusAPI

struct MainView_Previews: PreviewProvider {

    static var previews: some View {
        MainView(viewModel: AnyViewModel<MainState, MainInput>(MainViewModel(account: Mock.account, accountStorage: MockAccountStorage(), accountAPIService: nil, dealsAPIService: nil, resourcesAPIService: nil))) {

        }
    }
}

#endif
