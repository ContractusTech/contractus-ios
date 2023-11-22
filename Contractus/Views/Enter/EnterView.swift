//
//  EnterView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import SwiftUI
import enum ContractusAPI.Blockchain

struct EnterView: View {

    enum NavigateViewType: Hashable {
        case createWallet, importWallet
    }
    
    enum EnterViewType {
        case enterApp, addAccount
    }

    @StateObject var viewModel = AnyViewModel<EnterState, EnterInput>(EnterViewModel(
        initialState: EnterState(),
        accountService: AccountServiceImpl(storage: ServiceFactory.shared.makeAccountStorage()),
        backupStorage: ServiceFactory.shared.makeBackupStorage()))

    var viewType: EnterViewType = .enterApp

    @State private var selectedView: NavigateViewType? = .none
    @State private var blockchain: Blockchain = .solana
    @State private var showOnboarding: Bool = false

    var completion: (CommonAccount) -> Void

    var body: some View {
        wrapperBody {
            ZStack (alignment: .bottomLeading) {
                ScrollView {
                    switch viewType {
                    case .enterApp:
                        VStack(alignment: .center, spacing: 8) {
                            Text(R.string.localizable.enterSubtitle())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            VStack(alignment: .center, spacing: 0) {
                                Text(R.string.localizable.commonAppName())
                                    .font(.system(size: 41))
                                    .fontWeight(.semibold)
                                    .tracking(-1.1)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                #if IS_WALLET
                                Text(R.string.localizable.commonWallet())
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .tracking(-0.8)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(R.color.secondaryText.color)
                                #endif
                            }

                        }
                        .padding(EdgeInsets(top: 104, leading: 20, bottom: 20, trailing: 20))
                    case .addAccount:
                        VStack {
                            TopTextBlockView(
                                headerText: nil,
                                titleText: R.string.localizable.enterAddAccountTitle(),
                                subTitleText: R.string.localizable.enterAddAccountSubtitle(blockchain.rawValue.capitalized))

                            R.image.addAccount.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 220, height: 220)

                        }
                        .padding(.top, 16)
                    }
                }

                VStack {
                    /* TODO: - Solana by default, yet!
                    VStack {
                        Text("Blockchain")
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)

                        Menu(blockchain.rawValue.capitalized) {
                            ForEach(Blockchain.allCases, id: \.self) { item in
                                Button(item.rawValue.capitalized) {
                                    blockchain = item
                                }
                            }
                        }
                        .padding(10)
                        .background(R.color.buttonBackgroundSecondary.color.opacity(0.4))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 24)
                     */

                    if viewType == .enterApp {
                        Text(R.string.localizable.enterMessage(blockchain.rawValue.capitalized))
                            .font(.headline)
                            .foregroundColor(R.color.textBase.color)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 12)

                    }
                    NavigationLink(tag: NavigateViewType.createWallet, selection: $selectedView) {
                        CreateWalletView { account in
                            completion(account)
                        }
                        .environmentObject(viewModel)
                    } label: {
                        CButton(title: R.string.localizable.enterButtonCreate(), style: .primary, size: .large, isLoading: false)
                        {
                            EventService.shared.send(event: DefaultAnalyticsEvent.startNewAccountTap)
                            self.selectedView = .createWallet
                        }
                    }

                    NavigationLink(tag: NavigateViewType.importWallet, selection: $selectedView) {
                        ImportPrivateKeyView { account in
                            completion(account)
                        }
                        .environmentObject(viewModel)
                    } label: {
                        CButton(title: R.string.localizable.enterButtonImport(), style: .secondary, size: .large, isLoading: false)
                        {
                            EventService.shared.send(event: DefaultAnalyticsEvent.startImportAccountTap)
                            self.selectedView = .importWallet
                        }
                    }

                    if viewType == .enterApp {
                        Text(.init(R.string.localizable.enterTerms(AppConfig.terms.absoluteString, AppConfig.policy.absoluteString)))
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }
                }
                .padding(UIConstants.contentInset)
            }
            .onChange(of: blockchain, perform: { newValue in
                viewModel.trigger(.setBlockchain(newValue))
            })
            .onAppear{
                viewModel.trigger(.setBlockchain(blockchain))

                if ServiceFactory.shared.makeOnboardingService().needShowOnboarding() {
                    showOnboarding = true
                    EventService.shared.send(event: DefaultAnalyticsEvent.onboardingOpen)
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(viewModel: AnyViewModel<OnboardingState, OnboardingInput>(OnboardingViewModel(
                    contentType: .onboarding,
                    state: OnboardingState(state: .none, errorState: .none),
                    onboardingService: ServiceFactory.shared.makeOnboardingService()))
                ) {
                    showOnboarding.toggle()
                    EventService.shared.send(event: DefaultAnalyticsEvent.onboardingСlose)
                }
            }
            .baseBackground()
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    @ViewBuilder
    func wrapperBody<Content: View>(_ content: () -> Content) -> some View {
        switch viewType {
        case .enterApp:
            NavigationView {
                content()
            }
        case .addAccount:
            content()
        }
    }
}

struct EnterView_Previews: PreviewProvider {
    static var previews: some View {
        EnterView(completion: {_ in })
            .environmentObject(
                AnyViewModel<RootState, RootInput>(RootViewModel(
                    appManager: MockAppManager()
                ))
            )

        EnterView(viewType: .addAccount, completion: {_ in })
            .environmentObject(
                AnyViewModel<RootState, RootInput>(RootViewModel(
                    appManager: MockAppManager()
                ))
            )
    }
}

