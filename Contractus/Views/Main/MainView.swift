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

fileprivate enum Constants {
    static let arrowDownImage = Image(systemName: "chevron.down")
    static let plusImage = Image(systemName: "plus")
    static let menuImage = Image(systemName: "gearshape")
    static let qrCode = Image(systemName: "qrcode")
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
        case newDeal, menu, qrScan, sharePublicKey, wrap(from: Amount, to: Amount)
    }

    var resizableSheetCenter: ResizableSheetCenter? {
        guard let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) else {
            return nil
        }
        return ResizableSheetCenter.resolve(for: windowScene)
    }

    @StateObject var viewModel: AnyViewModel<MainState, MainInput>
    var logoutCompletion: () -> Void
    @State var selectedDeal: Deal?
    @State var sheetType: SheetType? = .none
    @State var dealsType: MainViewModel.State.DealType = .all
    @State var transactionSignType: TransactionSignType?


    @State private var showDealFilter: Bool = false
    
    var body: some View {

        JGProgressHUDPresenter(userInteractionOnHUD: true) {
            NavigationView {

                ScrollView {
                    VStack {
                        BalanceView(
                            state: viewModel.state.balance != nil ? .loaded(.init(balance: viewModel.state.balance!)) : .empty,
                            topUpAction: {

                            }) { fromAmount, toAmount in
                                sheetType = .wrap(from: fromAmount, to: toAmount)
                            }
                        HStack(alignment: .center) {
                            VStack {
                                Button {
                                    showDealFilter.toggle()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(dealTitle(type: dealsType))
                                            .font(.title.weight(.regular))
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
                                title: R.string.localizable.mainTitleNewDeal(),
                                icon: Constants.plusImage,
                                style: .primary,
                                size: .default,
                                isLoading: false) {
                                    sheetType = .newDeal
                                }

                        }
                        .padding(EdgeInsets(top: 16, leading: 8, bottom: 12, trailing: 8))

                        switch viewModel.state.dealsState {
                        case .loaded:
                            if viewModel.deals.isEmpty {
                                VStack(alignment: .center) {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 52, height: 52)
                                            .foregroundColor(R.color.secondaryText.color.opacity(0.3))
                                        Text("No active deals")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(R.color.secondaryText.color)
                                    }

                                    Spacer()
                                }
                                .padding(50)
                            } else {
                                LazyVGrid(columns: Constants.columns, spacing: 4) {
                                    ForEach(viewModel.deals, id: \.id) { item in
                                        Button {
                                            selectedDeal = item
                                        } label: {

                                            DealItemView(
                                                amountFormatted: item.amountFormatted,
                                                tokenSymbol: item.token.code,
                                                withPublicKey: item.getPartnersBy(viewModel.state.account.publicKey),
                                                status: item.status,
                                                roleType: dealRole(deal: item))

                                        }
                                    }
                                }
                                .padding(.bottom, 42)
                            }

                        case .loading:
                            HStack(alignment: .center) {
                                ProgressView()
                            }
                            .padding(50)
                        }
                    }
                    .padding(4)
                    

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
                .confirmationDialog(Text("Filter"), isPresented: $showDealFilter, actions: {
                    ForEach(MainViewModel.State.DealType.allCases, id: \.self) { type in
                        Button(dealTitle(type: type), role: .none) {
                            dealsType = type
                        }
                    }


                })

                .sheet(item: $sheetType, content: { type in
                    switch type {
                    case .wrap(let from, let to):
                        wrapView(amountNativeToken: from, amountWrapToken: to)
                            // .interactiveDismiss(canDismissSheet: false)
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
                                viewModel.trigger(.updateAccount)
                                load()
                            case .logout:
                                logoutCompletion()
                            }
                        }
                    case .qrScan:
                        QRCodeScannerView(configuration: .scannerAndInput, blockchain: viewModel.state.account.blockchain) { result in
                            viewModel.trigger(.executeScanResult(result))
                        }
                    case .sharePublicKey:
                        if let shareData = try? SharablePublicKey(shareContent: viewModel.state.account.publicKey) {
                            ShareContentView(content: shareData, topTitle: "Sharing", title: "Your public key", subTitle: "") { _ in

                            } dismissAction: {
                                sheetType = .none
                            }
                        } else {
                            EmptyView()
                        }
                    }
                })
                .navigationDestination(for: $selectedDeal) { deal in
                    dealView(deal: deal)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Button  {
                            sheetType = .sharePublicKey
                        } label: {
                            VStack(alignment: .center, spacing: 3) {
                                Text(R.string.localizable.commonAccount())
                                    .font(.callout)
                                    .fontWeight(.medium)
                                HStack {
                                    Constants.qrCode
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(R.color.accentColor.color)
                                    Text(ContentMask.mask(from: viewModel.state.account.publicKey))
                                        .font(.footnote)
                                        .foregroundColor(R.color.secondaryText.color)
                                }
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            sheetType = .menu
                        } label: {
                            Constants.menuImage
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            sheetType = .qrScan
                        } label: {
                            Constants.scanQRImage
                        }
                    }
                }
                .baseBackground()
                .edgesIgnoringSafeArea(.bottom)
            }
            .environment(\.resizableSheetCenter, resizableSheetCenter ?? PreviewResizableSheetCenter.shared)
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarColor()
            .onAppear{
                load()
            }
            .tintIfCan(R.color.textBase.color)
        }
    }

    @ViewBuilder
    func dealView(deal: Deal) -> some View {
        DealView(viewModel: AnyViewModel<DealState, DealInput>(DealViewModel(
            state: DealState(account: viewModel.account, availableTokens: viewModel.availableTokens, deal: deal),
            dealService: try? APIServiceFactory.shared.makeDealsService(),
            transactionSignService: ServiceFactory.shared.makeTransactionSign(),
            filesAPIService: try? APIServiceFactory.shared.makeFileService(),
            secretStorage: SharedSecretStorageImpl())),
                 availableTokens: viewModel.availableTokens) {
                viewModel.trigger(.load(dealsType))
            }
    }

    @ViewBuilder
    func wrapView(amountNativeToken: Amount, amountWrapToken: Amount) -> some View {

        WrapTokenView(viewModel: AnyViewModel<WrapTokenState, WrapTokenInput>(WrapTokenViewModel(state: .init(account: viewModel.account, amountNativeToken: amountNativeToken, amountWrapToken: amountWrapToken), accountService: (try? APIServiceFactory.shared.makeAccountService()))))
    }

    private func dealRole(deal: Deal) -> DealItemView.DealRoleType {
        if deal.ownerPublicKey == viewModel.state.account.publicKey
            && deal.ownerRole == .executor {
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
            return "Latest"
        case .isChecker:
            return "For checking"
        case .isClient:
            return "As client"
        case .isExecutor:
            return "For execute"
        }
    }

    private func load() {
        viewModel.trigger(.preload)
        viewModel.trigger(.load(dealsType))
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
