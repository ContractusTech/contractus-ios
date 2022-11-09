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

struct RootState: Equatable {
    static func == (lhs: RootState, rhs: RootState) -> Bool {
        if case .hasAccount(let account1) = lhs.state, case .hasAccount(let account2) = rhs.state {
            return account1.publicKey == account2.publicKey
        }

        if case .noAccount = lhs.state, case .noAccount = rhs.state {
            return true
        }
        return false
    }

    enum State {
        case hasAccount(Account), noAccount
    }
    var state: State = .noAccount
}

enum RootInput {
    case savedAccount(Account), logout
}

final class RootViewModel: ViewModel {

    @Published var state: RootState
    private let accountStorage: AccountStorage

    init(accountStorage: AccountStorage) {
        self.accountStorage = accountStorage
        if
            let pk = accountStorage.getPrivateKey(),
            let account = try? Account(secretKey: pk)
        {
            // TODO: - Не очень правильное решение
            APIServiceFactory.shared.setAccount(for: account)
            self.state = RootState(state: .hasAccount(account))
        } else {
            self.state = RootState(state: .noAccount)
        }

    }

    func trigger(_ input: RootInput, after: AfterTrigger? = nil) {
        switch input {
        case .savedAccount(let account):
            APIServiceFactory.shared.setAccount(for: account)
            state.state = .hasAccount(account)
        case .logout:
            state.state = .noAccount
            APIServiceFactory.shared.clearAccount()
            accountStorage.deletePrivateKey()
        }
    }
}


@main
struct ContractusApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var rootViewModel = AnyViewModel<RootState, RootInput>(RootViewModel(accountStorage: KeychainAccountStorage()))

    var body: some Scene {
        WindowGroup {
            Group {
                EmptyView().DebugPrint("Render")
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
                        dealsAPIService: try? APIServiceFactory.shared.makeDealsService())), logoutCompletion: {
                        rootViewModel.trigger(.logout)
                    })

                    .navigationTitle("Contractus")
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading))
                    )
                }

            }

            .animation(.default, value: rootViewModel.state)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        appearanceSetup()
        return true
    }
}

fileprivate func appearanceSetup() {
    if let color = R.color.textBase() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: color]
        UINavigationBar.appearance().barTintColor = color
        UINavigationBar.appearance().tintColor = color
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: color]
    }
}
