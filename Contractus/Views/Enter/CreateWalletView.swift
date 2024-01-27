//
//  CreateWalletView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import SwiftUI
import SolanaSwift

fileprivate enum Constants {
    // TODO: - 
}

struct CreateWalletView: View {

    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>

    @State private var isActive: Bool = false
    var completion: (CommonAccount) -> Void

    var body: some View {
        ZStack (alignment: .bottomLeading) {
            if let account = viewModel.state.account {
                ScrollView {

                    VStack(alignment: .center, spacing: 24) {

                        BaseTopTextBlockView(
                            titleText: R.string.localizable.createWalletTitle(), subTitleText: R.string.localizable.createWalletSubtitle())
//                        TopTextBlockView(
//                            informationType: .none,
//                            headerText: "New wallet",
//                            titleText: R.string.localizable.createWalletTitle(),
//                            subTitleText: R.string.localizable.createWalletSubtitle())
                        CopyContentView(content: ContentMask.mask(from: account.privateKeyEncoded()), contentType: .privateKey) { _ in
                            viewModel.trigger(.copyPrivateKey)
                        }
                        Spacer()
                    }
                    .padding(UIConstants.contentInset)
                }

                HStack {
                    NavigationLink(isActive: $isActive) {
                        BackupInformationView(
                            informationType: .warning,
                            titleText: "Your Safety",
                            largeTitleText: R.string.localizable.backupInformationTitle(),
                            informationText: R.string.localizable.backupInformationSubtitle(),
                            privateKey: account.privateKeyEncoded(),
                            completion: {
                                completion(account)
                            }).environmentObject(viewModel)

                    } label: {

                        CButton(title: R.string.localizable.createWalletButtonNext(), style: .primary, size: .large, isLoading: false) {
                            isActive = true
                        }

                    }
                }
                .padding(UIConstants.contentInset)
            }
        }
        .onAppear {
            viewModel.trigger(.createIfNeeded)
        }
        .baseBackground()
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)

    }
}


struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateWalletView(completion: {_ in })
                .environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(account: Mock.account, blockchain: .solana), accountService: AccountServiceImpl(storage: MockAccountStorage()), backupStorage: BackupStorageMock()))
                )
                .preferredColorScheme(.dark)
        }

    }
}
