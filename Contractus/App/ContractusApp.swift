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

struct RootState {
    enum State {
        case hasAccount(CommonAccount), noAccount
    }

    enum TransactionState: Equatable {
        case none, needSign(TransactionSignType)
    }
    var state: State = .noAccount
    var transactionState: TransactionState = .none
}

enum RootInput {
    case savedAccount(CommonAccount), logout, signTx(TransactionSignType), cancelTx
}

final class RootViewModel: ViewModel {

    @Published private(set) var state: RootState
    private let accountStorage: AccountStorage
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""

    init(accountStorage: AccountStorage) {
        self.accountStorage = accountStorage
        if let account = accountStorage.getCurrentAccount() {
            // TODO: - Не очень правильное решение + вынести deviceId
            APIServiceFactory.shared.setAccount(for: account, deviceId: deviceId)
            self.state = RootState(state: .hasAccount(account))
        } else {
            self.state = RootState(state: .noAccount)
        }
    }

    func trigger(_ input: RootInput, after: AfterTrigger? = nil) {
        switch input {
        case .savedAccount(let account):
            APIServiceFactory.shared.setAccount(for: account, deviceId: deviceId)
            state.state = .hasAccount(account)
        case .signTx(let type):
            state.transactionState = .needSign(type)
        case .cancelTx:
            state.transactionState = .none
        case .logout:
            state.state = .noAccount
            APIServiceFactory.shared.clearAccount()
            accountStorage.clearCurrentAccount()
        }
    }
}

let appState = AnyViewModel<RootState, RootInput>(RootViewModel(accountStorage: KeychainAccountStorage()))

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
            .animation(.default, value: rootViewModel.state)
        }
    }

    @ViewBuilder
    func signView(account: CommonAccount) -> some View {
        if let transactionSignType = transactionSignType {
            TransactionSignView(account: account, type: transactionSignType) {

            } cancelAction: {
                showTxSheet = false
            }
        } else {
            EmptyView()
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
