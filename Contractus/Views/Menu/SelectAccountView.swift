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

struct SelectAccountView: View {
    enum SheetType {
        case backup(CommonAccount), delete(CommonAccount)
    }

    enum ActionsSheetType: Equatable {
        case addActions
    }

    enum NavigateViewType: Hashable {
        case addWallet, createWallet, importWallet
    }

    @Environment(\.editMode) var editMode

    @State var items: [CommonAccount]
    @Binding var selectedItem: CommonAccount?
    var accountDeleteHandler: (_ accounts: [CommonAccount]) -> Void
    var logoutHandler: () -> Void

    @State private var confirmAlert: Bool = false
    @State private var deletedActiveAccount: Bool = false
    @State private var actionsType: ActionsSheetType?
    @State private var selectedView: NavigateViewType? = .none
    @State private var sheetType: SheetType? = .none

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                if editMode?.wrappedValue == .active {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(R.string.localizable.accountsWarningTitle())
                                .font(.headline)
                                .foregroundColor(R.color.textBase.color)
                            Text(R.string.localizable.accountsWarningSubtitle())
                                .font(.subheadline)
                                .foregroundColor(R.color.textBase.color)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 19)
                    .padding(.horizontal, 21)
                    .background(
                        R.color.yellow200.color
                            .clipped()
                            .cornerRadius(20)
                    )
                    
                    MenuSectionView(height: 16)
                }
                
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ContentMask.mask(from: item.publicKey))
                            Text(item.blockchain.rawValue.capitalized)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                        Spacer()
                        if editMode?.wrappedValue == .active {
                            CButton(title: R.string.localizable.accountsEditPrivateKey(), style: .secondary, size: .small, isLoading: false, roundedCorner: true) {
                                sheetType = .backup(item)
                            }
                            CButton(title: R.string.localizable.accountsEditRemove(), style: .cancel, size: .small, isLoading: false, roundedCorner: true) {
                                sheetType = .delete(item)
                            }
                            .padding(.trailing, 13)
                        } else {
                            Group {
                                if self.selectedItem == item {
                                    ZStack {
                                        Constants.checkmarkImage
                                            .imageScale(.small)
                                            .foregroundColor(R.color.accentColor.color)
                                    }
                                    .frame(width: 24, height: 24)
                                    .background(R.color.fourthBackground.color)
                                    .cornerRadius(7)
                                } else {
                                    ZStack {}
                                        .frame(width: 24,  height: 24)
                                        .overlay(
                                            RoundedRectangle(
                                                cornerRadius: 7,
                                                style: .continuous
                                            )
                                            .stroke(R.color.fourthBackground.color, lineWidth: 1)
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
                        self.selectedItem = item
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
                        add(account)
                    }
                } label: {
                    EmptyView()
                }
            }
            .padding(.horizontal, 5)
        }
        .baseBackground()
        .navigationTitle(R.string.localizable.accountsTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .alert(isPresented: $confirmAlert) {
            Alert(
                title: Text(R.string.localizable.accountsDeleteAlertTitle()),
                message: Text(R.string.localizable.accountsDeleteAlertSubtitle()),
                primaryButton: Alert.Button.destructive(Text(R.string.localizable.accountsDeleteAlertButton()), action: {
                    if deletedActiveAccount {
                        accountDeleteHandler(items)
                        logoutHandler()
                    } else {
                        accountDeleteHandler([])
                    }
                }),
                secondaryButton: Alert.Button.cancel {
                    editMode?.wrappedValue = .inactive
                }
            )
        }
        .actionSheet(item: $actionsType, content: { type in
            switch type {
            case .addActions:
                return ActionSheet(
                    title: Text(R.string.localizable.commonSelectAction()),
                    buttons: actionSheetMenuButtons()
                )
            }
        })
        .sheet(item: $sheetType, content: { type in
            switch type {
            case .backup(let item):
                DeleteBackupView(
                    informationType: .none,
                    titleText: R.string.localizable.commonBackup(),
                    largeTitleText: R.string.localizable.accountsBackupTitle(),
                    informationText: R.string.localizable.accountsBackupSubtitle(),
                    privateKey: item.privateKey,
                    completion: { type in
                        switch type {
                        case .copyPrivateKey:
                            return
                        default:
                            self.sheetType = .none
                        }
                    }
                )
            case .delete(let item):
                DeleteBackupView(
                    viewType: .delete,
                    informationType: .warning,
                    titleText: R.string.localizable.commonAttention(),
                    largeTitleText: R.string.localizable.accountsDeleteTitle(),
                    informationText: R.string.localizable.accountsDeleteSubtitle(),
                    privateKey: item.privateKey,
                    completion: { type in
                        switch type {
                        case .cancel:
                            self.sheetType = .none
                        case .delete:
                            self.sheetType = .none
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                remove(item)
                            }
                        case .copyPrivateKey:
                            return
                        }
                    }
                )
            }
        })
    }

    func add(_ item: CommonAccount) {
        var _items = items
        _items.append(item)
        items = _items
        accountDeleteHandler(items)
    }
    
    func remove(_ item: CommonAccount) {
        var _items = items
        _items.removeAll { $0 == item }
        if _items.isEmpty {
            confirmAlert.toggle()
            return
        } else if let selectedItem = selectedItem, !_items.contains(selectedItem) {
            confirmAlert.toggle()
            deletedActiveAccount = true
            return
        }
        deletedActiveAccount = false
        items = _items
        accountDeleteHandler(items)
    }
    
    private func actionSheetMenuButtons() -> [Alert.Button] {
        return [
            Alert.Button.default(Text(R.string.localizable.enterButtonCreateWallet())) {
                self.selectedView = .createWallet
            },
            Alert.Button.default(Text(R.string.localizable.enterButtonImport())) {
                self.selectedView = .importWallet
            },
            Alert.Button.cancel() {
                
            }]
    }
}

extension SelectAccountView.ActionsSheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

extension SelectAccountView.SheetType: Identifiable {
    var id: String {
        return "\(self)"
    }
}

struct SelectAccountView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AnyViewModel<MenuState, MenuInput>(MenuViewModel(accountStorage: MockAccountStorage()))
        SelectAccountView(
            items: viewModel.accounts,
            selectedItem: .constant(nil),
            accountDeleteHandler: { _ in },
            logoutHandler: {}
        )
    }
}
