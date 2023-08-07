//
//  SelectAccountView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.03.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
    static let plusImage = Image(systemName: "plus.circle.fill")
}

extension CommonAccount: Identifiable {
    var id: String {
        self.publicKey
    }
}

struct AccountsView: View {

    enum HandlerAction {
        case logout, changeAccount
    }

    enum SheetType {
        case backup(AccountsViewModel.AccountItem), delete(AccountsViewModel.AccountItem)
    }

    enum ActionsSheetType: Equatable {
        case addActions
    }

    enum NavigateViewType: Hashable {
        case addWallet, createWallet, importWallet
    }
    @Environment(\.editMode) var editMode

    @StateObject var viewModel: AnyViewModel<AccountsViewModel.State, AccountsViewModel.Input>
    var handler: (HandlerAction) -> Void

    @State private var confirmAlert: Bool = false
    @State private var deletedActiveAccount: Bool = false
    @State private var actionsType: ActionsSheetType?
    @State private var selectedView: NavigateViewType? = .none
    @State private var sheetType: SheetType? = .none

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
//                if editMode?.wrappedValue == .active {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 6) {
//                            Text(R.string.localizable.accountsWarningTitle())
//                                .font(.headline)
//                                .foregroundColor(R.color.textBase.color)
//                            Text(R.string.localizable.accountsWarningSubtitle())
//                                .font(.subheadline)
//                                .foregroundColor(R.color.textBase.color)
//                        }
//                        Spacer()
//                    }
//                    .padding(.vertical, 19)
//                    .padding(.horizontal, 21)
//                    .background(
//                        R.color.yellow200.color
//                            .clipped()
//                            .cornerRadius(20)
//                    )
//
//                    MenuSectionView(height: 16)
//                }
                
                ForEach(viewModel.state.accounts, id: \.self) { item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ContentMask.mask(from: item.account.publicKey))
                            Text(item.account.blockchain.rawValue.capitalized)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        Spacer()
                        if editMode?.wrappedValue == .active {
                            CButton(title: R.string.localizable.commonBackup(), style: .secondary, size: .small, isLoading: false, roundedCorner: false) {
                                sheetType = .backup(item)
                            }
                            CButton(title: R.string.localizable.accountsEditRemove(), style: .cancel, size: .small, isLoading: false, roundedCorner: false) {
                                sheetType = .delete(item)
                            }
                            .padding(.trailing, 13)
                        } else {
                            Group {
                                if self.viewModel.state.currentAccount == item.account {
                                    ZStack {
                                        Constants.checkmarkImage
                                            .imageScale(.small)
                                            .foregroundColor(R.color.buttonTextPrimary.color)
                                    }
                                    .frame(width: 24, height: 24)
                                    .background(R.color.accentColor.color)
                                    .cornerRadius(7)
                                } else {
                                    ZStack {}
                                        .frame(width: 24,  height: 24)
                                        .overlay(
                                            RoundedRectangle(
                                                cornerRadius: 7,
                                                style: .continuous
                                            )
                                            .stroke(R.color.accentColor.color, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.trailing, 19)
                        }
                    }
                    .frame(height: 62)
                    .padding(.leading, 21)
                    .background(
                        Color(R.color.secondaryBackground()!)
                            .clipped()
                            .cornerRadius(20)
                    )
                    .onTapGesture {
                        viewModel.trigger(.changeAccount(item.account))
                    }
                }
                if editMode?.wrappedValue != .active {
                    
                    MenuSectionView()
                    
                    HStack {
                        Spacer()
                        Constants.plusImage
                        Text(R.string.localizable.accountsAdd())
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 16)
                    .background(
                        Color(R.color.secondaryBackground()!)
                            .clipped()
                            .cornerRadius(20)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedView = .addWallet
                    }
                }
                
                NavigationLink(tag: NavigateViewType.addWallet, selection: $selectedView) {
                    EnterView(viewType: .addAccount) { account in
                        selectedView = .none
                        viewModel.trigger(.changeAccount(account))
                        viewModel.trigger(.reload)
                    }
                } label: {
                    EmptyView()
                }
            }
            .padding(.horizontal, 5)
            .onChange(of: viewModel.state.currentAccount) { newValue in
                handler(.changeAccount)
            }
        }
        .baseBackground()
        .navigationTitle(R.string.localizable.accountsTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
//        .alert(isPresented: $confirmAlert) {
//            Alert(
//                title: Text(R.string.localizable.accountsDeleteAlertTitle()),
//                message: Text(R.string.localizable.accountsDeleteAlertSubtitle()),
//                primaryButton: Alert.Button.destructive(Text(R.string.localizable.accountsDeleteAlertButton()), action: {
//                    if deletedActiveAccount {
//                        accountDeleteHandler(items)
//                        logoutHandler()
//                    } else {
//                        accountDeleteHandler([])
//                    }
//                }),
//                secondaryButton: Alert.Button.cancel {
//                    editMode?.wrappedValue = .inactive
//                }
//            )
//        }
//        .actionSheet(item: $actionsType, content: { type in
//            switch type {
//            case .addActions:
//                return ActionSheet(
//                    title: Text(R.string.localizable.commonSelectAction()),
//                    buttons: actionSheetMenuButtons()
//                )
//            }
//        })
        .sheet(item: $sheetType, content: { type in
            accountView(type: type)
        })
    }

    private func actionSheetMenuButtons() -> [Alert.Button] {
        return [
            Alert.Button.default(Text(R.string.localizable.enterButtonCreate())) {
                self.selectedView = .createWallet
            },
            Alert.Button.default(Text(R.string.localizable.enterButtonImport())) {
                self.selectedView = .importWallet
            },
            Alert.Button.cancel() {
                
            }]
    }

    
    private func accountView(type: SheetType) -> some View {
        var title: String
        var largeTitle: String
        var informationType: TopTextBlockView.InformationType
        var informationText: String
        var privateKey: Data
        var viewType: AboutAccountView.ViewType
        var account: CommonAccount
        switch type {
        case .backup(let item):
            informationType = .none
            title = R.string.localizable.commonBackup()
            largeTitle =  R.string.localizable.accountsBackupTitle()
            informationText = R.string.localizable.accountsBackupSubtitle()
            privateKey = item.account.privateKey
            viewType = .backup(existInBackup: item.existInBackup)
            account = item.account

        case .delete(let item):
            informationType = .warning
            title = R.string.localizable.commonAttention()
            largeTitle = R.string.localizable.accountsDeleteTitle()
            informationText = R.string.localizable.accountsDeleteSubtitle()
            privateKey = item.account.privateKey
            viewType = .delete(existInBackup: item.existInBackup)
            account = item.account
        }
        return AboutAccountView(
            viewType: viewType,
            informationType: informationType,
            titleText: title,
            largeTitleText: largeTitle,
            informationText: informationText,
            privateKey: privateKey,
            completion: { type in
                self.sheetType = .none
                switch type {
                case .delete(let fromBackup):
                    viewModel.trigger(.deleteAccount(account, fromBackup: fromBackup))
                    break
                case .backup(let backupToICloud):
                    viewModel.trigger(.backup(account, allow: backupToICloud))
                case .none:
                    break

                }
            }
        )
    }
}

extension AccountsView.ActionsSheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

extension AccountsView.SheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView(
            viewModel: .init(
                AccountsViewModel(
                    accountStorage: MockAccountStorage(),
                    backupStorage: BackupStorageMock()
                )
            )
        ) { _ in

        }
    }
}
