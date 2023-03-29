//
//  MenuView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.11.2022.
//

import SwiftUI

struct MenuItemView<Destination>: View where Destination: View {
    var icon: String
    var title: String
    var linkTo: Destination
    
    var body: some View {
        NavigationLink {
            linkTo
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                .background(Color.black)
                .cornerRadius(9)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(R.color.whiteSeparator.color)
            }
            .frame(height: 62)
            .padding(.horizontal, 16)
            .background(
                Color(R.color.secondaryBackground()!)
                    .clipped()
                    .cornerRadius(20)
            )
        }
        .listRowSeparator(.hidden)
    }
}

struct MenuSectionView: View {
    var height: Float = 28

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: CGFloat(height))
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
                ScrollView {
                    VStack(spacing: 2) {
                        MenuItemView (
                            icon: "person.2.circle.fill",
                            title: "Accounts",
                            linkTo: SelectAccountView(
                                items: viewModel.accounts,
                                selectedItem: $selectedAccount
                            ) { accounts in
                                viewModel.trigger(.saveAccounts(accounts))
                            } logoutHandler: {
                                action(.logout)
                            })
                        
                        MenuSectionView()
                        
                        MenuItemView (
                            icon: "slider.horizontal.3",
                            title: "Common settings",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: "lock.fill",
                            title: "Security",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: "bell.badge",
                            title: "Push notifications",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: "person.crop.rectangle.stack.fill",
                            title: "Common settings",
                            linkTo: EmptyView()
                        )
                        
                        MenuSectionView()
                        
                        MenuItemView (
                            icon: "questionmark.circle",
                            title: "F.A.Q.",
                            linkTo: EmptyView()
                        )
                    }
                }
                .padding(.horizontal, 5)

                if tapCount > 3 {
                    NavigationLink {
                        ServerSelectView(items: [.developer(), .production()])
                    } label: {
                        Text(versionFormatted)
                    }
                } else {
                    Text(versionFormatted)
                        .foregroundColor(R.color.secondaryText.color)
                        .font(.footnote.weight(.medium))
                        .onTapGesture {
                            tapCount+=1
                        }
                }
            }
            .baseBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selectedAccount = viewModel.currentAccount
        }
        .onChange(of: selectedAccount, perform: { selected in
            if let selected = selected, selected != viewModel.currentAccount {
                viewModel.trigger(.changeAccount(selected))
            }
        })
        .navigationBarColor()
    }

    var selectedAccountFormatted: String {
        return "\(selectedAccount?.blockchain.rawValue.capitalized ?? "") • \(ContentMask.mask(from: selectedAccount?.publicKey))"
    }
    
    var versionFormatted: String {
        return String(format: "v.%@ build %@", AppConfig.version, AppConfig.buildNumber)
    }
}

    
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(viewModel: AnyViewModel<MenuState, MenuInput>(MenuViewModel(accountStorage: MockAccountStorage()))) { _ in

            
        }
    }
}
