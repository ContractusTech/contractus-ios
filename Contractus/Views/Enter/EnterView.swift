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

    @StateObject var viewModel = AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: KeychainAccountStorage())))

    @State private var selectedView: NavigateViewType? = .none
    @State private var blockchain: Blockchain = .solana

    var completion: (CommonAccount) -> Void

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading, spacing: 24) {
                    Text(R.string.localizable.commonAppName())
                        .font(.title)
                        .fontWeight(.heavy)
                    Text(R.string.localizable.enterMessage())
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(EdgeInsets(top: 44, leading: 20, bottom: 20, trailing: 20))
                Spacer()
                VStack {
                    VStack {
                        Text("Blockchain")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                        Picker("", selection: $blockchain) {
                            ForEach(Blockchain.allCases, id: \.self) { item in
                                HStack {
                                    Text(item.rawValue.capitalized)
                                        .font(.body.weight(.medium))
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .background(R.color.buttonBackgroundSecondary.color.opacity(0.4))
                        .cornerRadius(12)

                    }
                    .padding(.bottom, 24)
                    NavigationLink(tag: NavigateViewType.createWallet, selection: $selectedView) {
                        CreateWalletView { account in
                            completion(account)
                        }
                        .environmentObject(viewModel)
                    } label: {
                        Button {
                            self.selectedView = .createWallet
                        } label: {
                            HStack {
                                Spacer()
                                Text(R.string.localizable.enterButtonCreateWallet())
                                Spacer()
                            }
                        }.buttonStyle(PrimaryLargeButton())
                    }

                    NavigationLink(tag: NavigateViewType.importWallet, selection: $selectedView) {
                        ImportPrivateKeyView()
                            .environmentObject(viewModel)
                    } label: {
                        Button {
                            self.selectedView = .importWallet
                        } label: {
                            HStack {
                                Spacer()
                                Text(R.string.localizable.enterButtonImport())
                                Spacer()
                            }
                        }
                        .buttonStyle(SecondaryLargeButton())
                    }
                }
                .padding(EdgeInsets(top: 10, leading: 16, bottom: 42, trailing: 16))

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

