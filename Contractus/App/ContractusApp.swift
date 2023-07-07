//
//  ContractusApp.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import SwiftUI
import SolanaSwift
import UIKit
import ResizableSheet
import netfox
import ContractusAPI

struct RootState {
    enum State {
        case hasAccount(CommonAccount), noAccount, loading, error(Error)
    }

    enum TransactionState: Equatable {
        case none, needSign(TransactionSignType)
    }
    var state: State = .noAccount
    var transactionState: TransactionState = .none
}

enum RootInput {
    case savedAccount(CommonAccount), logout, signTx(TransactionSignType), cancelTx, reload
}

final class RootViewModel: ViewModel {

    @Published private(set) var state: RootState
    private let appManager: AppManager

    init(appManager: AppManager) {
        self.appManager = appManager
        self.state = .init(state: .loading)
        self.reload()
    }

    func trigger(_ input: RootInput, after: AfterTrigger? = nil) {
        switch input {
        case .savedAccount(let account):
            appManager.setAccount(for: account)
            state.state = .hasAccount(account)
        case .signTx(let type):
            state.transactionState = .needSign(type)
        case .cancelTx:
            state.transactionState = .none
        case .logout:
            state.state = .noAccount
            appManager.clearAccount()
        case .reload:
            state.state = .loading
            appManager.clearAccount()
            reload()

        }
    }

    func reload() {
        Task { @MainActor [weak self] in
            do {
                try await appManager.sync()
                self?.state.state = .hasAccount(appManager.currentAccount)
            } catch AppManagerImpl.AppManagerError.noCurrentAccount {
                self?.state.state = .noAccount
                AppManagerImpl.shared.clearAccount()
                debugPrint(".noAccount")
            } catch {
                self?.state.state = .error(error)
                debugPrint(error.readableDescription)
            }
        }
    }
}

let appState = AnyViewModel<RootState, RootInput>(RootViewModel(appManager: AppManagerImpl.shared))

@main
struct ContractusApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var rootViewModel = appState
    @State private var showTxSheet: Bool = false

    private var transactionSignType: TransactionSignType? {
        switch rootViewModel.transactionState {
        case .needSign(let tx):
            return tx
        case .none:
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch rootViewModel.state.state {
                case .error(let error):
                    errorView(error: error)
                case .loading:
                    syncView()
                case .noAccount:
                    EnterView(completion: { account in
                        rootViewModel.trigger(.savedAccount(account))
                    })
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading))
                    )
                case .hasAccount(let account):
                    MainView(viewModel: AnyViewModel<MainState, MainInput>(MainViewModel(
                        account: account,
                        accountStorage: ServiceFactory.shared.makeAccountStorage(),
                        accountAPIService: try? APIServiceFactory.shared.makeAccountService(),
                        dealsAPIService: try? APIServiceFactory.shared.makeDealsService(),
                        resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService())), logoutCompletion: {
                            rootViewModel.trigger(.logout)
                        })
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading))
                    )
                    .onChange(of: rootViewModel.state.transactionState, perform: { txState in
                        switch txState {
                        case .needSign:
                            showTxSheet = true
                        case .none:
                            showTxSheet = false
                        }
                    })
                    .rootSheet(isPresented: $showTxSheet, onDismiss: nil, content: {
                        signView(account: account)
                    })
                }
            }
            .navigationBarColor()
            .animation(.default, value: rootViewModel.state)
        }
    }

    @ViewBuilder
    func signView(account: CommonAccount) -> some View {
        if let transactionSignType = transactionSignType {
            TransactionSignView(account: account, type: transactionSignType) {

            } closeAction: { _ in
                showTxSheet = false
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func syncView() -> some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Spacer()
        }
    }

    @ViewBuilder
    func errorView(error: Error) -> some View {
        HStack {
            Text("Error device identification")
            HStack {
                Button {
                    rootViewModel.trigger(.reload)
                } label: {
                    Text("Try again")
                        .font(.body.bold())
                }

                Button {

                } label: {
                    Text("Get debug info")
                        .font(.body.bold())
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        appearanceSetup()
        
        if case .developer = AppConfig.serverType {
            NFX.sharedInstance().start()
        }

        return true
    }
}

fileprivate func appearanceSetup() {
    if let color = R.color.textBase() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: color]
        UINavigationBar.appearance().barTintColor = color
        UINavigationBar.appearance().tintColor = color
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: color]
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = color
    }
}


extension RootState: Equatable {

    static func == (lhs: RootState, rhs: RootState) -> Bool {
        if case .hasAccount(let account1) = lhs.state, case .hasAccount(let account2) = rhs.state {
            return account1.publicKey == account2.publicKey
        }

        if case .noAccount = lhs.state, case .noAccount = rhs.state {
            return true
        }
        return false
    }

}
