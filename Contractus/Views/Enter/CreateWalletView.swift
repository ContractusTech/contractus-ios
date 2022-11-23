//
//  CreateWalletView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import SwiftUI
import SolanaSwift

fileprivate enum Constants {
    static let successCopyImage = Image(systemName: "checkmark")
    static let keyImage = Image(systemName: "key.viewfinder")
}

struct CreateWalletView: View {

    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>
    @State var copiedNotification: Bool = false

    var completion: (CommonAccount) -> Void

    var body: some View {
        VStack(alignment: .center) {
            if let account = viewModel.state.account {
                VStack(alignment: .center, spacing: 24) {
//                    Constants.keyImage
//                        .resizable()
//                        .frame(width: 140, height: 140, alignment: .center)
//                        .padding()
//                    Text(R.string.localizable.createWalletTitle())
//                        .font(.largeTitle)
//                    Text(R.string.localizable.createWalletSubtitle())
//                        .font(.body)
//                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        Text("New wallet")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.secondaryText.color)

                        Text(R.string.localizable.createWalletTitle())
                            .font(.largeTitle.weight(.heavy))
                        Text(R.string.localizable.createWalletSubtitle())
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))

                    CopyContentView(content: account.privateKey.toHexString(), contentType: .privateKey) { _ in
                        viewModel.trigger(.copyPrivateKey)
                        withAnimation(.easeInOut) {
                            copiedNotification = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation(.easeInOut) {
                                    copiedNotification = false
                                }
                            }
                        }
                    }

                    HStack {
                        Constants.successCopyImage
                        Text(R.string.localizable.createWalletButtonCopied())
                    }
                    .opacity(copiedNotification ? 1 : 0)
                    Spacer()
                }
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center
                )
                Spacer()
                HStack {
                    NavigationLink {
                        BackupInformationView(
                            titleText: "New wallet",
                            largeTitleText: R.string.localizable.backupInformationTitle(),
                            informationText: R.string.localizable.backupInformationSubtitle(),
                            privateKey: account.privateKey,
                            completion: {
                            completion(account)
                        }).environmentObject(viewModel)

                    } label: {
                        HStack {
                            Spacer()
                            Text(R.string.localizable.createWalletButtonNext())
                            Spacer()
                        }
                    }.buttonStyle(PrimaryLargeButton())
                }
                .padding(.bottom, 24)

            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .leading)
        .padding()

        .onAppear {
            viewModel.trigger(.createIfNeeded)
        }
        .baseBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor()
        .edgesIgnoringSafeArea(.bottom)

    }
}


struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateWalletView(completion: {_ in })
                .environmentObject(AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: EnterState(), accountService: AccountServiceImpl(storage: MockAccountStorage())))
                )
                .preferredColorScheme(.dark)
        }

    }
}
