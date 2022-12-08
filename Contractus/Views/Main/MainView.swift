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
    static let menuImage = Image(systemName: "gearshape")
    static let qrCode = Image(systemName: "qrcode")
    static let scanQRImage = Image(systemName: "qrcode.viewfinder")
    static let columns: [GridItem] = {
        return [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }()
}

struct MainView: View {

    enum SheetType {
        case newDeal, menu, qrScan, sharePublicKey
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

    var body: some View {
        NavigationView {

            ScrollView {
                VStack {
                    BalanceView(
                        state: viewModel.state.balance != nil ? .loaded(viewModel.state.balance!) : .empty,
                        topUpAction: {

                        })
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(R.string.localizable.mainTitleDeals())
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(R.string.localizable.mainTitleActiveContracts("\(viewModel.state.deals.count)"))
                                .font(.footnote.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        Spacer()

                        CButton(
                            title: R.string.localizable.mainTitleNewDeal(),
                            style: .primary,
                            size: .default,
                            isLoading: false) {
                                sheetType = .newDeal
                        }

                    }
                    .padding(EdgeInsets(top: 24, leading: 0, bottom: 8, trailing: 0))
                    LazyVGrid(columns: Constants.columns) {
                        ForEach(viewModel.deals, id: \.id) { item in
                            Button {
                                selectedDeal = item
                            } label: {
                                DealItemView(
                                    deal: item,
                                    needPayment: item.ownerPublicKey == viewModel.state.account.publicKey && item.ownerRole == .executor)
                            }
                        }
                    }
                }
                .padding(15)

            }.refreshableCompat(loadingViewBackgroundColor: .clear, onRefresh: { done in
                viewModel.trigger(.load) {
                    done()
                }
            }, progress: { state in
                RefreshActivityIndicator(isAnimating: state == .loading) {
                    $0.hidesWhenStopped = false
                }
            })

            .sheet(item: $sheetType, content: { type in
                switch type {
                case .newDeal:
                    CreateDealView(
                        viewModel: AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(
                            account: viewModel.state.account,
                            accountAPIService: try? APIServiceFactory.shared.makeAccountService(),
                            dealsAPIService: try? APIServiceFactory.shared.makeDealsService()))) { deal in
                                selectedDeal = deal
                                viewModel.trigger(.load)
                            }
                            .interactiveDismiss(canDismissSheet: false)
                case .menu:
                    MenuView(viewModel: AnyViewModel<MenuState, MenuInput>(MenuViewModel(accountStorage: KeychainAccountStorage()))) { action in
                        switch action {
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
                            Text("Account")
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
            viewModel.trigger(.load)
        }
        .tintIfCan(R.color.textBase.color)

        
    }

    @ViewBuilder
    func dealView(deal: Deal) -> some View {
        DealView(viewModel: AnyViewModel<DealState, DealInput>(DealViewModel(
            state: DealState(account: viewModel.account, deal: deal),
            dealService: try? APIServiceFactory.shared.makeDealsService(),
            transactionSignService: ServiceFactory.shared.makeTransactionSign(), filesAPIService: try? APIServiceFactory.shared.makeFileService(),
            secretStorage: SharedSecretStorageImpl()))) {
                viewModel.trigger(.load)
            }
    }
}

extension MainView.SheetType: Identifiable {
    var id: String {
        switch self {
        case .newDeal:
            return "newDeal"
        case .menu:
            return "menu"
        case .qrScan:
            return "qrScan"
        case .sharePublicKey:
            return "sharePublicKey"
        }
    }
}

// MARK: - Previews

#if DEBUG
import ContractusAPI

struct MainView_Previews: PreviewProvider {

    static var previews: some View {
        MainView(viewModel: AnyViewModel<MainState, MainInput>(MainViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil))) {

        }
    }
}

#endif
