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
    static let columns: [GridItem] = {
        return [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }()
}

struct MainView: View {

    enum SheetType {
        case newDeal
    }

    var resizableSheetCenter: ResizableSheetCenter? {
        guard let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) else {
            return nil
        }
        return ResizableSheetCenter.resolve(for: windowScene)
    }

    @StateObject var viewModel: AnyViewModel<MainState, MainInput>
    var logoutCompletion: () -> Void
    @State var sheetType: SheetType?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    BalanceView(
                        state: viewModel.state.balance != nil ? .loaded(viewModel.state.balance!) : .empty,
                        topUpAction: {

                        })
                    HStack {
                        VStack(alignment: .leading) {
                            Text(R.string.localizable.mainTitleContracts())
                                .font(.title)
                                .fontWeight(.semibold)
                            Text(R.string.localizable.mainTitleActiveContracts("\(viewModel.state.deals.count)"))
                                .font(.footnote.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        Spacer()
                        Button {
                            sheetType = .newDeal
                        } label: {
                            Text(R.string.localizable.commonCreate())
                        }
                        .buttonStyle(PrimaryMediumButton())
                    }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    LazyVGrid(columns: Constants.columns) {
                        ForEach(viewModel.deals, id: \.id) { item in
                            NavigationLink {
                                DealView(viewModel: AnyViewModel<DealState, DealInput>(DealViewModel(
                                    state: DealState(account: viewModel.account, deal: item),
                                    dealService: try? APIServiceFactory.shared.makeDealsService(),
                                    transactionSignService: ServiceFactory.shared.makeTransactionSign(),
                                    secretStorage: SharedSecretStorageImpl()))
                                )
                            } label: {
                                DealItemView(deal: item) {
                                }
                            }
                        }
                    }
                }
                .padding(20)

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
                            dealsAPIService: try? APIServiceFactory.shared.makeDealsService()))) {
                                viewModel.trigger(.load)
                            }
                            .interactiveDismiss(canDismissSheet: false)
                }
            })

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        R.image.contractusLogo.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 12)

                        Text(KeyFormatter.format(from: viewModel.state.account.publicKey.base58EncodedString))
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        logoutCompletion()
                    } label: {
                        Text("Exit")
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
}

extension MainView.SheetType: Identifiable {
    var id: String {
        switch self {
        case .newDeal:
            return "newDeal"
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
