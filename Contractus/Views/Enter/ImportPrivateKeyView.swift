//
//  ImportPrivateKeyView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.10.2022.
//

import SwiftUI

struct ImportPrivateKeyView: View {

    @ObservedObject private var keyboard = KeyboardResponder(defaultHeight: UIConstants.contentInset.bottom)
    
    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>

    @State var privateKey: String = ""
    @State var isActiveBackup: Bool = false
    var completion: (CommonAccount) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack {
                    TopTextBlockView(
                        headerText: "Import",
                        titleText: "Enter private key",
                        subTitleText: "Of the client who will perform the work under the contract.")

                    VStack(alignment: .center, spacing: 24) {
                        MultilineTextFieldView(placeholder: "Enter private key", value: $privateKey)


                        if viewModel.state.isValidImportedPrivateKey {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Your public key")
                                        .font(.footnote.weight(.semibold))
                                        .textCase(.uppercase)
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                                HStack {
                                    Text(ContentMask.mask(from: viewModel.state.account?.publicKey))
                                        .font(.body)
                                    Spacer()
                                }

                            }
                        }
                    }
                }
                .padding(UIConstants.contentInset)
                .padding(.bottom, keyboard.currentHeight)
                .animation(.easeOut(duration: 0.16))
            }

            NavigationLink(isActive: $isActiveBackup) {
                if let account = viewModel.state.account {
                    BackupInformationView(
                        informationType: .success,
                        titleText: "Import successful",
                        largeTitleText: "You safety",
                        informationText: "Save your private key to secure store so you don't lose access to your account ",
                        privateKey: account.privateKey,
                        completion: {
                        completion(account)
                    }).environmentObject(viewModel)
                } else {
                    EmptyView()
                }


            } label: {
                CButton(title: "Import", style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.isValidImportedPrivateKey) {
                    isActiveBackup.toggle()
                }
            }
            .disabled(!viewModel.isValidImportedPrivateKey)
            .padding(UIConstants.contentInset)
        }
        .navigationBarColor()
        .baseBackground()
        .tintIfCan(R.color.textBase.color)
        .onChange(of: privateKey, perform: { newValue in
            viewModel.trigger(.importPrivateKey(newValue))
        })
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)


    }
}

struct ImportPrivateKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportPrivateKeyView { _ in

        }.environmentObject(
            AnyViewModel<EnterState, EnterInput>(EnterViewModel(initialState: .init(account: Mock.account, isValidImportedPrivateKey: true), accountService: AccountServiceImpl(storage: MockAccountStorage())))
        )
    }
}
