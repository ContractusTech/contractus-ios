//
//  AppConfig.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI

enum AppConfig {

#if DEBUG
    static let serverType: ServerType = ConfigStorage.getServer(defaultServer: .developer())
#else
    static let serverType: ServerType = ConfigStorage.getServer(defaultServer: .production())
#endif
    
    // Length secret key for encrypt content of deal.
    // IMPORTANT: only 64
    static let sharedKeyLength = 64
    
    static let supportEmail = "support@contractus.tech"

    static let supportTelegram = "https://t.me/ContractusSupportBot"

    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""

    static let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""

    static let bundleId = Bundle.main.bundleIdentifier!
    
    static let isSmallScreen: Bool = UIScreen.main.bounds.width / UIScreen.main.bounds.height > 0.5

    // MARK: - Information URL's

    static let tiersInformationURL: URL = URL(string: "https://contractus.gitbook.io/docs/tiers")!

    static let holderModeURL: URL = URL(string: "https://contractus.gitbook.io/docs/holder-mode")!

    static let faqURL: URL = URL(string: "https://contractus.gitbook.io/docs/faq")!

    static let lockedFundsURL: URL = URL(string: "https://contractus.gitbook.io/docs/faq")!

    static let feesURL: URL = URL(string: "https://contractus.gitbook.io/docs/fees")!

    static let ctusInfoURL: URL = URL(string: "https://contractus.gitbook.io/docs/ctus-token")!
    
    static let terms: URL = URL(string: "https://files.contractus.tech/Contractus-Terms.pdf")!
    
    static let policy: URL = URL(string: "https://files.contractus.tech/Contractus-PrivacyPolicy.pdf")!
}
