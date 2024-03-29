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
import AppsFlyerLib

fileprivate enum Constants {
    static let mainTabIcon = R.image.homeFill.image
    static let profileTabIcon = R.image.accountCircleFill.image
    static let peopleTabIcon = R.image.teamFill.image
}

struct RootState {
    enum TabTag: String, CaseIterable, Identifiable {
        var id: String {
            return self.rawValue
        }
        case main
//        case people
//        case profile

        var image: Image {
            switch self {

            case .main:
                Constants.mainTabIcon
//            case .people:
//                Constants.peopleTabIcon
//            case .profile:
//                Constants.profileTabIcon
            }
        }
    }

    enum State {
        case hasAccount(CommonAccount, notification: NotificationHandler.NotificationType? = nil), noAccount, loading, error(Error)
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
                self.state.state = .hasAccount(self.appManager.currentAccount, notification: NotificationHandler.notification)
            } catch AppManagerImpl.AppManagerError.noCurrentAccount {
                self.state.state = .noAccount
                AppManagerImpl.shared.clearAccount()
                debugPrint(".noAccount")
            } catch {
                self.state.state = .error(error)
                debugPrint(error.localizedDescription)
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
    @State private var selectionTab: RootState.TabTag = .main

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
                case .hasAccount(let account, let notification):
                    ZStack(alignment: .bottom) {
                        TabView(selection: $selectionTab) {
                            ForEach(RootState.TabTag.allCases) { item in
                                tabView(tab: item, account: account, notification: notification)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .ignoresSafeArea()
                        .animation(.easeOut(duration: 0.2), value: selectionTab)
                        .transition(.slide)

                        if RootState.TabTag.allCases.count > 1 {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    ForEach(RootState.TabTag.allCases) { item in
                                        Button {
                                            selectionTab = item
                                        } label: {
                                            item.image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 28, height: 28)
                                                .foregroundColor(R.color.textBase.color)
                                                .opacity(selectionTab == item ? 1.0 : 0.4)
                                                .padding(11)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(32)
                                Spacer()
                            }
                        }

                    }
                    .onChange(of: selectionTab) { newValue in
                        debugPrint(newValue)
                    }


                }
            }
            .navigationBarColor()
            .animation(.default, value: rootViewModel.state)
            .background(R.color.mainBackground.color)
        }
    }

    @ViewBuilder
    func mainView(account: CommonAccount, notification: NotificationHandler.NotificationType?) -> some View {
        MainView(viewModel: AnyViewModel<MainState, MainInput>(MainViewModel(
            account: account,
            accountStorage: ServiceFactory.shared.makeAccountStorage(),
            accountAPIService: try? APIServiceFactory.shared.makeAccountService(),
            dealsAPIService: try? APIServiceFactory.shared.makeDealsService(),
            resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService(),
            checkoutService: APIServiceFactory.shared.makeCheckoutService(),
            secretStorage: SharedSecretStorageImpl(),
            notification: notification)), logoutCompletion: {
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
    func tabView(tab: RootState.TabTag, account: CommonAccount, notification: NotificationHandler.NotificationType? = nil) -> some View {
        switch tab {
        case .main:
            mainView(account: account, notification: notification)
                .tag(tab)
//        case .people:
//            EmptyView()
//                .tag(tab)
//        case .profile:
//            EmptyView()
//                .tag(tab)
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
                Text(error.localizedDescription)

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

        if !Env.APPSFLYER_DEV_KEY.isEmpty && !Env.APPLE_APP_ID.isEmpty {
            AppsFlyerLib.shared().appsFlyerDevKey = Env.APPSFLYER_DEV_KEY
            AppsFlyerLib.shared().appleAppID = Env.APPLE_APP_ID
        }

        application.registerForRemoteNotifications()

        let remoteNotification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification]
        if let remoteNotification = remoteNotification as? [AnyHashable: Any] {
            NotificationHandler.handler(notification: remoteNotification)
        }

        MigrationManager.migrateIfNeeded()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if !Env.APPSFLYER_DEV_KEY.isEmpty {
            AppsFlyerLib.shared().start()
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
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
extension AppDelegate: UNUserNotificationCenterDelegate {

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
        Messaging.messaging().apnsToken = deviceToken
        AppManagerImpl.shared.setupNotifications()
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
        NotificationHandler.handler(notification: userInfo)

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
        if case .hasAccount(let account1, let notification1) = lhs.state, case .hasAccount(let account2, let notification2) = rhs.state {
            return account1.publicKey == account2.publicKey && notification1 == notification2
        }

        if case .noAccount = lhs.state, case .noAccount = rhs.state {
            return true
        }
        return false
    }

}

// HOTFIX: - For ResizableSheet. Not display keyboard after set hidden state.
func switchToMainWindow() {
    UIApplication.shared.connectedScenes
        .map { $0 as? UIWindowScene }
        .compactMap { $0 }
        .first?.windows
        .first { !$0.isKeyWindow }?.makeKey()
}

func isiOSAppOnMac() -> Bool {
    if #available(iOS 14.0, *) {
        return ProcessInfo.processInfo.isiOSAppOnMac
    }
    return false
}
