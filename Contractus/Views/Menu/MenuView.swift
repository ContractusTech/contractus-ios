//
//  MenuView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.11.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let rightArrowIcon = Image(systemName: "chevron.right")
    static let personIcon = Image(systemName: "person.2.circle.fill")
    static let sliderIcon = Image(systemName: "slider.horizontal.3")
    static let lockIcon = Image(systemName: "lock.fill")
    static let bellIcon = Image(systemName: "bell.badge")
    static let personCropIcon = Image(systemName: "person.crop.rectangle.stack.fill")
    static let faqIcon = Image(systemName: "questionmark.circle")

}

struct MenuItemView<Destination>: View where Destination: View {
    var icon: Image
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
                        icon.foregroundColor(R.color.textBase.color)
                    }
                    .frame(width: 32, height: 32)
                    .background(R.color.mainBackground.color)
                    .cornerRadius(9)
                    Text(title)
                    Spacer()
                    Constants.rightArrowIcon
                        .foregroundColor(R.color.whiteSeparator.color)
                }
                .frame(height: 62)
                .padding(.horizontal, 16)
                .background(
                    R.color.secondaryBackground.color
                        .clipped()
                        .cornerRadius(17)
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
                            icon: Constants.personIcon,
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
                        #if DEBUG 
                        MenuItemView (
                            icon: Constants.sliderIcon,
                            title: "Common settings",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: Constants.lockIcon,
                            title: "Security",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: Constants.bellIcon,
                            title: "Push notifications",
                            linkTo: EmptyView()
                        )
                        MenuItemView (
                            icon: Constants.personCropIcon,
                            title: "Common settings",
                            linkTo: EmptyView()
                        )
                        
                        MenuSectionView()
                        
                        MenuItemView (
                            icon: Constants.faqIcon,
                            title: "F.A.Q.",
                            linkTo: EmptyView()
                        )
                        #endif
                    }
                }
                .padding(.horizontal, 5)

                Text(versionFormatted)
                    .foregroundColor(R.color.secondaryText.color)
                    .font(.footnote.weight(.medium))
                    .onTapGesture(count: 3, perform: {
                        showServerSelection.toggle()
                    })
                    .padding()

            }
            .sheet(isPresented: $showServerSelection, content: {
                ServerSelectView()
            })
            .baseBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                interactiveDismiss = true
            }
        }
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
