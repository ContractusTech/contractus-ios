//
//  MenuView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.11.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
}
extension CommonAccount: Identifiable {
    var id: String {
        self.publicKey
    }
}

struct SelectAccountView: View {

    @Environment(\.editMode) var editMode

    @State var items: [CommonAccount]
    @Binding var selectedItem: CommonAccount?
    var accountDeleteHandler: (_ accounts: [CommonAccount]) -> Void
    var logoutHandler: () -> Void

    @State private var confirmAlert: Bool = false
    @State private var deletedActiveAccount: Bool = false

    var body: some View {
        Form {
            if editMode?.wrappedValue == .active {
                Section {
                    VStack(alignment: .leading) {
                        Text("Warning")
                            .font(.body.weight(.medium))
                            .foregroundColor(R.color.yellow.color)
                        Text("Check backup private key before delete account!")
                            .font(.callout)
                            .foregroundColor(R.color.yellow.color)
                    }
                }
            }
            Section {
                HStack {
                    Button("Add account") {
                        
                    }
                }
            }

            List {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 12) {
                        Text(ContentMask.mask(from: item.publicKey))
                        Text(item.blockchain.rawValue.capitalized)
                            .foregroundColor(R.color.secondaryText.color)
                        Spacer()
                        if self.selectedItem == item {
                            Constants.checkmarkImage.foregroundColor(R.color.accentColor.color)
                        }
                    }
                    .onTapGesture {
                        self.selectedItem = item
                    }
                }.onDelete(perform: remove)
            }
        }
        .toolbar {
            EditButton()
        }
        .alert(isPresented: $confirmAlert) {
            Alert(
                title: Text("Warning"),
                message: Text("Please select another account before deleting the active account. Or after deleting you log out. Delete account?"),
                primaryButton: Alert.Button.destructive(Text("Yes, delete"), action: {
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
    }

    func remove(at offsets: IndexSet) {
        var _items = items
        _items.remove(atOffsets: offsets)
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

}

struct MenuView: View {

    enum ActionType {
        case logout
    }

    @StateObject var viewModel: AnyViewModel<MenuState, MenuInput>
    @State private var selectedAccount: CommonAccount?
    @State private var tapCount: Int = 0
    
    var action: (ActionType) -> Void

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        NavigationLink {
                            SelectAccountView(items: viewModel.accounts, selectedItem: $selectedAccount) { accounts in
                                viewModel.trigger(.saveAccounts(accounts))
                            } logoutHandler: {
                                action(.logout)
                            }
                        } label: {
                            HStack {
                                Text("Account")
                                Spacer()
                                Text(selectedAccountFormatted)
                                    .foregroundColor(R.color.secondaryText.color)
                            }
                        }
                    }
                    Section {
                        Button("Exit") {
                            action(.logout)
                        }
                        .foregroundColor(R.color.redText.color)
                    }
                    
                }
                if tapCount > 3 {
                    NavigationLink {
                        ServerSelectView(items: [.developer(), .production()])
                    } label: {
                        Text(versionFormatted)
                    }
                } else {
                    Text(versionFormatted)
                        .onTapGesture {
                            tapCount+=1
                        }
                }
            }
            .baseBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }.onAppear {
            selectedAccount = viewModel.currentAccount
        }
        .navigationBarColor()
    }

    var selectedAccountFormatted: String {
        return "\(selectedAccount?.blockchain.rawValue.capitalized ?? "") • \(ContentMask.mask(from: selectedAccount?.publicKey))"
    }
    
    var versionFormatted: String {
        return String(format: "v.%@ (%@)", AppConfig.version, AppConfig.buildNumber)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(viewModel: AnyViewModel<MenuState, MenuInput>(MenuViewModel(accountStorage: MockAccountStorage()))) { _ in

            
        }
    }
}
