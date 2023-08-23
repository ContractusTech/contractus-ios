//
//  MenuView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.11.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let rightArrowIcon = Image(systemName: "chevron.right")
    static let personIcon = Image(systemName: "person.2.circle")
    static let sliderIcon = Image(systemName: "slider.horizontal.3")
    static let lockIcon = Image(systemName: "lock.fill")
    static let bellIcon = Image(systemName: "bell.badge")
    static let personCropIcon = Image(systemName: "person.crop.rectangle.stack.fill")
    static let faqIcon = Image(systemName: "questionmark.circle")
    static let supportIcon = Image(systemName: "lifepreserver")
    static let giftIcon = Image(systemName: "giftcard")
}

struct MenuItemView<Destination>: View where Destination: View {
    var icon: Image
    var title: String
    var linkTo: Destination?

    var tapHandler: (() -> Void)?
    @State private var isActive: Bool = false

    var body: some View {
        if let linkTo = linkTo {
            NavigationLink(isActive: $isActive){
                linkTo
            } label: {
                itemView()
            }
            .listRowSeparator(.hidden)
        } else {
            itemView()
                .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    func itemView() -> some View {
        Button {
            tapHandler?()
            isActive.toggle()
        } label: {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(R.color.textBase.color)
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
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
            )
        }
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
                            title: R.string.localizable.menuAccounts(),
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
                                    EventService.shared.send(event: DefaultAnalyticsEvent.settingsAccountsTap)
                                    interactiveDismiss = false
                                }
                        
                        MenuSectionView()
                        #if DEBUG 
//                        MenuItemView (
//                            icon: Constants.sliderIcon,
//                            title: "Common settings",
//                            linkTo: EmptyView()
//                        )
                        MenuItemView (
                            icon: Constants.giftIcon,
                            title: R.string.localizable.menuReferralProgram(),
                            linkTo: ReferralView()
                        )
                        MenuItemView<EmptyView> (
                            icon: Constants.supportIcon,
                            title: R.string.localizable.menuSupport()
                        ) {
                            let appURL = URL(string: "mailto:\(AppConfig.supportEmail)")!
                            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                        }
//                        MenuItemView (
//                            icon: Constants.lockIcon,
//                            title: "Security",
//                            linkTo: EmptyView()
//                        )
//                        MenuItemView (
//                            icon: Constants.bellIcon,
//                            title: "Push notifications",
//                            linkTo: EmptyView()
//                        )
//                        MenuItemView (
//                            icon: Constants.personCropIcon,
//                            title: "Common settings",
//                            linkTo: EmptyView()
//                        )
                        
                        MenuSectionView()
                        #endif
                        MenuItemView (
                            icon: Constants.faqIcon,
                            title: R.string.localizable.menuFaq(),
                            linkTo: faqView
                        ) {
                            EventService.shared.send(event: DefaultAnalyticsEvent.settingsFaqTap)
                        }
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
            .navigationTitle(R.string.localizable.menuTitle())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                EventService.shared.send(event: DefaultAnalyticsEvent.settingsOpen)
                interactiveDismiss = true
            }
        }
        .interactiveDismissDisabled(!interactiveDismiss)
    }

    var faqView: some View {
        WebView(url: AppConfig.faqURL)
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle(R.string.localizable.menuFaq())
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var versionFormatted: String {
        return R.string.localizable.menuVersion(AppConfig.version, AppConfig.buildNumber)
    }
}

    
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView { _ in

            
        }
    }
}
