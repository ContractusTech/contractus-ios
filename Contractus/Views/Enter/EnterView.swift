//
//  EnterView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import SwiftUI
import SolanaSwift

struct EnterView: View {

    enum NavigateViewType: Hashable {
        case createWallet, importWallet
    }

    @StateObject var viewModel = AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: KeychainAccountStorage())))

    @State private var selectedView: NavigateViewType? = .none
    var completion: (SolanaSwift.Account) -> Void

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

