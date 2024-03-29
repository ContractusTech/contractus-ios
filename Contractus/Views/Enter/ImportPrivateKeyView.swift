//
//  ImportPrivateKeyView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.10.2022.
//

import SwiftUI

struct ImportPrivateKeyView: View {

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }
    
    @ObservedObject private var keyboard = KeyboardResponder(defaultHeight: UIConstants.contentInset.bottom)
    
    @EnvironmentObject var viewModel: AnyViewModel<EnterState, EnterInput>
    @State private var alertType: AlertType?
    @State private var privateKey: String = ""
    @State private var isActiveBackup: Bool = false
    @State private var showBackupKeys: Bool = false

    var completion: (CommonAccount) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack {

                    BaseTopTextBlockView(
                        titleText: R.string.localizable.importWalletTitle(),
                        subTitleText: R.string.localizable.importWalletSubtitle())

                    VStack(alignment: .center, spacing: 24) {
                        MultilineTextFieldView(placeholder: R.string.localizable.importWalletPlaceholder(), value: $privateKey)
                        if !privateKey.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(R.string.localizable.importWalletPublicKey())
                                        .font(.footnote.weight(.semibold))
                                        .textCase(.uppercase)
                                        .foregroundColor(R.color.secondaryText.color)
                                    Spacer()
                                }
                                if viewModel.state.isValidImportedPrivateKey {
                                    HStack {
                                        Text(ContentMask.mask(from: viewModel.state.account?.publicKey))
                                            .font(.body)
                                        Spacer()
                                    }
                                } else {
                                    HStack {
                                        Text(R.string.localizable.importWalletInvalidKey())
                                            .font(.footnote)
                                            .foregroundColor(R.color.labelBackgroundError.color)
                                        Spacer()
                                    }

                                }
                            }
                        }
                        if viewModel.state.hasBackupKeys {
                            HStack() {
                                VStack {
                                    Text(R.string.localizable.importWalletFoundKeysTitle(String(viewModel.state.backupKeys.count)))
                                        .font(.body.weight(.regular))
                                        .foregroundColor(R.color.secondaryText.color)

                                }
                                Spacer()
                                Divider()
                                    .background(R.color.baseSeparator.color)
                                    .rotationEffect(.degrees(0.5))
                                    .padding(.trailing, 6)

                                Button {
                                    showBackupKeys.toggle()
                                } label: {
                                    Text(R.string.localizable.commonSelect())
                                        .font(.body.weight(.medium))
                                }
                            }
                            .padding(16)
                            .background(content: {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(R.color.baseSeparator.color)
                            })
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
                        titleText: R.string.localizable.importWalletSuccessTitle(),
                        largeTitleText: R.string.localizable.importWalletSuccessLabel(),
                        informationText: R.string.localizable.importWalletSuccessDescription(),
                        privateKey: account.privateKeyEncoded(),
                        completion: {
                        completion(account)
                    }).environmentObject(viewModel)
                } else {
                    EmptyView()
                }
            } label: {
                CButton(title: R.string.localizable.commonImport(), style: .primary, size: .large, isLoading: false, isDisabled: !viewModel.isValidImportedPrivateKey) {
                    isActiveBackup.toggle()
                }
            }
            .disabled(!viewModel.isValidImportedPrivateKey)
            .padding(UIConstants.contentInset)
        }
        .baseBackground()
        .tintIfCan(R.color.textBase.color)
        .onChange(of: privateKey, perform: { newValue in
            viewModel.trigger(.importPrivateKey(newValue))
        })
        .onChange(of: viewModel.state.errorState) { value in
            switch value {
            case .error(let errorMessage):
                self.alertType = .error(errorMessage)
            case .none:
                self.alertType = .none
            }
        }
        .alert(item: $alertType, content: { type in
            switch type {
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message),
                    dismissButton: .default(Text(R.string.localizable.commonOk()), action: {
                        viewModel.trigger(.hideError)
                    }))
            }
        })
        .actionSheet(isPresented: $showBackupKeys, content: {
            ActionSheet(
                title: Text(R.string.localizable.importWalletSelectBackupKeyTitle()),
                buttons: privateKeysButtons())
        })
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)


    }

    private func privateKeysButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = viewModel.state.backupKeys.map { pk in
                .default(Text(ContentMask.mask(from: pk.publicKey)), action: {
                    privateKey = pk.privateKey
            })
        }

        buttons.append(.cancel())
        return buttons
    }
}

struct ImportPrivateKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportPrivateKeyView { _ in

        }.environmentObject(
            AnyViewModel<EnterState, EnterInput>(EnterViewModel(
                initialState: .init(account: Mock.account, isValidImportedPrivateKey: true),
                accountService: AccountServiceImpl(storage: MockAccountStorage()),
                backupStorage: BackupStorageMock()))
        )
    }
}
