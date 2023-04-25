//
//  EnterView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import SwiftUI
import enum ContractusAPI.Blockchain

struct EnterView: View {

    enum NavigateViewType: Hashable {
        case createWallet, importWallet
    }
    
    enum EnterViewType {
        case enterApp, addAccount
    }

    @StateObject var viewModel = AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: KeychainAccountStorage())))

    var viewType: EnterViewType = .enterApp

    @State private var selectedView: NavigateViewType? = .none
    @State private var blockchain: Blockchain = .solana

    var completion: (CommonAccount) -> Void

    var body: some View {
        wrapperBody {
            ZStack (alignment: .bottomLeading) {
                ScrollView {
                    switch viewType {
                    case .enterApp:
                        HStack(alignment: .center, spacing: 16) {
                            Spacer()
                            Text(R.string.localizable.commonAppName())
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .tracking(-1.1)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }

                        .padding(EdgeInsets(top: 104, leading: 20, bottom: 20, trailing: 20))
                    case .addAccount:
                        // TODO: - Move text in localization
                        TopTextBlockView(
                            headerText: "Add new",
                            titleText: "Account",
                            subTitleText: "To add account select blockchain type and create or import your wallet")
                    }
                }

                VStack {
                    /* TODO: - Solana by default, yet!
                    VStack {
                        Text("Blockchain")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)

                        Menu(blockchain.rawValue.capitalized) {
                            ForEach(Blockchain.allCases, id: \.self) { item in
                                Button(item.rawValue.capitalized) {
                                    blockchain = item
                                }
                            }
                        }
                        .padding(10)
                        .background(R.color.buttonBackgroundSecondary.color.opacity(0.4))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 24)
                     */

                    if viewType == .enterApp {
                        Text(R.string.localizable.enterMessage(blockchain.rawValue.capitalized))
                            .font(.headline)
                            .foregroundColor(R.color.textBase.color)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 12)

                    }
                    NavigationLink(tag: NavigateViewType.createWallet, selection: $selectedView) {
                        CreateWalletView { account in
                            completion(account)
                        }
                        .environmentObject(viewModel)
                    } label: {
                        CButton(title: R.string.localizable.enterButtonCreateWallet(), style: .primary, size: .large, isLoading: false)
                        {
                            self.selectedView = .createWallet
                        }
                    }

                    NavigationLink(tag: NavigateViewType.importWallet, selection: $selectedView) {
                        ImportPrivateKeyView { account in
                            completion(account)
                        }
                        .environmentObject(viewModel)
                    } label: {
                        CButton(title: R.string.localizable.enterButtonImport(), style: .secondary, size: .large, isLoading: false)
                        {
                            self.selectedView = .importWallet
                        }
                    }
                }
                .padding(UIConstants.contentInset)
            }
            .onChange(of: blockchain, perform: { newValue in
                viewModel.trigger(.setBlockchain(newValue))
            })
            .onAppear{
                viewModel.trigger(.setBlockchain(blockchain))
            }
            .baseBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor()
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    @ViewBuilder
    func wrapperBody<Content: View>(_ content: () -> Content) -> some View {
        switch viewType {
        case .enterApp:
            NavigationView {
                content()
            }
        case .addAccount:
            content()
        }
    }
}

struct EnterView_Previews: PreviewProvider {
    static var previews: some View {
        EnterView(completion: {_ in })
            .environmentObject(
                AnyViewModel<RootState, RootInput>(RootViewModel(
                    accountStorage: MockAccountStorage()
                ))
            )
    }
}

