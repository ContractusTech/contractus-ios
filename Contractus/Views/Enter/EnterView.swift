import SwiftUI
import enum ContractusAPI.Blockchain

fileprivate enum Constants {
    static let solanaImage = R.image.solana.image
    static let bscImage = R.image.bsc.image
}

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
    @State private var blockchain: Blockchain = .bsc
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
                            Text(R.string.localizable.commonAppName())
                                .font(.system(size: 41))
                                .fontWeight(.semibold)
                                .tracking(-1.1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(EdgeInsets(top: 104, leading: 20, bottom: 20, trailing: 20))
                    case .addAccount:
                        VStack {
                            TopTextBlockView(
                                headerText: nil,
                                titleText: R.string.localizable.enterAddAccountTitle(),
                                subTitleText: R.string.localizable.enterAddAccountSubtitle(blockchain.longTitle))

                            R.image.addAccount.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 220, height: 220)

                        }
                        .padding(.top, 16)
                    }
                }

                VStack {
                    Text(R.string.localizable.commonSelectBlockchain())
                        .font(.headline)
                        .foregroundColor(R.color.textBase.color)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 6)
                    HStack {
                        HStack {
                            ForEach(Blockchain.allCases, id: \.self) { item in
                                Button {
                                    blockchain = item
                                    ImpactGenerator.soft()
                                } label: {
                                    HStack {
                                        item.image
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .aspectRatio(contentMode: .fit)

                                        Text(item.title)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(blockchain == item ? R.color.buttonTextPrimary.color : R.color.textBase.color)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(blockchain == item ? R.color.accentColor.color : .clear)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke()
                                .fill(R.color.baseSeparator.color)
                        }
                    }
                    .padding()

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

extension Blockchain {
    var image: Image {
        switch self {
        case .bsc:
            return Constants.bscImage
        case .solana:
            return Constants.solanaImage
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

