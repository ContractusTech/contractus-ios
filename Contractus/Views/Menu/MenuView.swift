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

    var tapHandler: (() -> Void)?
    @State private var isActive: Bool = false

    var body: some View {
        NavigationLink(isActive: $isActive){
            linkTo
        } label: {
            Button {
                tapHandler?()
                isActive.toggle()
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
        case logout, changeAccount
    }

    @State private var tapCount: Int = 0
    @State private var interactiveDismiss: Bool = true
    @State private var showServerSelection: Bool = false
    
    var handler: (ActionType) -> Void

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 2) {
                        MenuItemView (
                            icon: "person.2.circle.fill",
                            title: "Accounts",
                            linkTo: AccountsView(viewModel: .init(AccountsViewModel(
                                accountStorage: ServiceFactory.shared.makeAccountStorage(),
                                backupStorage: ServiceFactory.shared.makeBackupStorage()))) { actionType in
                                    switch actionType {
                                    case .changeAccount:
                                        handler(.changeAccount)
                                    case .logout:
                                        break
                                    }
                                    // TODO: - Logout handler
                                }) {
                                    interactiveDismiss = false
                                }
                        
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

                Text(versionFormatted)
                    .foregroundColor(R.color.secondaryText.color)
                    .font(.footnote.weight(.medium))
                    .onTapGesture(count: 3, perform: {
                        showServerSelection.toggle()
                    })

            }
            .sheet(isPresented: $showServerSelection, content: {
                ServerSelectView(items: [.developer(), .production()])
            })
            .baseBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                interactiveDismiss = true
            }
        }
        .navigationBarColor()
        .interactiveDismissDisabled(!interactiveDismiss)
    }
    
    var versionFormatted: String {
        return String(format: "v.%@ build %@", AppConfig.version, AppConfig.buildNumber)
    }
}

    
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView { _ in

            
        }
    }
}
