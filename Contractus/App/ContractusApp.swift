import SwiftUI
import SolanaSwift
import UIKit
import ResizableSheet
import netfox
import ContractusAPI
import Combine
import Firebase
import FirebaseMessaging
import UserNotifications

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
        self.appManager.invalidDeviceHandler = { error in
            DispatchQueue.main.async {
                self.state = .init(state: .error(error))
            }
        }
    }

    func trigger(_ input: RootInput, after: AfterTrigger? = nil) {
        switch input {
        case .savedAccount(let account):
            appManager.setAccount(for: account)
            reload()
        case .signTx(let type):
            state.transactionState = .needSign(type)
        case .cancelTx:
            state.transactionState = .none
        case .logout:
            state.state = .noAccount
            appManager.clearAccount()
        case .reload:
            state.state = .loading
            // appManager.clearAccount()
            reload()
        }
    }

    func debugInfo() -> [String] {
        appManager.debugInfo()
    }

    private func reload() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await self.appManager.sync()
                self.state.state = .hasAccount(self.appManager.currentAccount)
            } catch AppManagerImpl.AppManagerError.noCurrentAccount {
                self.state.state = .noAccount
                AppManagerImpl.shared.clearAccount()
                debugPrint(".noAccount")
            } catch {
                self.state.state = .error(error)
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
    @State private var showServerSelection = false

    private var transactionSignType: TransactionSignType? {
        switch rootViewModel.transactionState {
        case .needSign(let tx):
            return tx
        case .none:
            return nil
        }
    }

    var resizableSheetCenter: ResizableSheetCenter? {
        guard let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) else {
            return nil
        }
        return ResizableSheetCenter.resolve(for: windowScene)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch rootViewModel.state.state {
                case .error(let error):
                    errorView(error: error)
                        .sheet(isPresented: $showServerSelection, content: {
                            ServerSelectView()
                        })
                case .loading:
                    syncView()
                case .noAccount:
                    EnterView(completion: { account in
                        rootViewModel.trigger(.savedAccount(account))
                    })
                    .transition(AnyTransition.asymmetric(
                        insertion: .opacity,
                        removal: .opacity)
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
                    .environment(\.resizableSheetCenter, resizableSheetCenter)
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
            .background(R.color.mainBackground.color)
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
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName:  error.isDeviceCheckError ? "iphone.slash" : "wifi.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor( error.isDeviceCheckError ? R.color.yellow.color : R.color.blue.color)
                Text(error.readableDescription)

                HStack(spacing: 12) {
                    CButton(title: "Try again", style: .secondary, size: .default, isLoading: false) {
                        rootViewModel.trigger(.reload)
                    }

                    CButton(title: "Support", style: .primary, size: .default, isLoading: false) {
                        openEmailSupport()
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Information")
                        .bold()
                        .onTapGesture(count: 3, perform: {
                            showServerSelection.toggle()
                        })
                    ForEach(AppManagerImpl.shared.debugInfo(), id: \.self) { item in
                        Text(item)
                            .font(.callout)
                    }
                    CButton(title: "Copy", style: .secondary, size: .small, isLoading: false) {
                        UIPasteboard.general.string = AppManagerImpl.shared.debugInfo().joined(separator: "\n")
                        ImpactGenerator.light()
                    }
                }
            }
            .padding(EdgeInsets(top: 32, leading: 16, bottom: 24, trailing: 16))
            .background(R.color.secondaryBackground.color)
            .cornerRadius(20)
        }




    }
}

fileprivate extension Error {
    var isDeviceCheckError: Bool {
        let error = (self as? ContractusAPI.APIClientError)
        switch error {
        case .serviceError(let error):
            return error.statusCode == 423
        default:
            return false
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        appearanceSetup()

        switch AppConfig.serverType  {
        case .local, .developer:
            NFX.sharedInstance().start()
        default:
            #if DEBUG
            NFX.sharedInstance().start()
            #endif
        }

        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        EventService.shared.send(event: DefaultAnalyticsEvent.startApp)

        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
#if DEBUG
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        print(userInfo)
#endif
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
#if DEBUG
        let deviceToken:[String: String] = ["token": fcmToken ?? ""]
        print("Device token: ", deviceToken)
#endif

    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
#if DEBUG
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
#endif

        completionHandler([[.banner, .badge, .sound]])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
#if DEBUG
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID from userNotificationCenter didReceive: \(messageID)")
        }
        
        print(userInfo)
#endif
        Messaging.messaging().appDidReceiveMessage(userInfo)

        completionHandler()
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
    UIPageControl.appearance().currentPageIndicatorTintColor = R.color.accentColor()
    UIPageControl.appearance().pageIndicatorTintColor = R.color.baseSeparator()
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
