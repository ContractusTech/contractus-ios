//
//  AppConfig.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI

enum AppConfig {

    static let serverType: ServerType = ConfigStorage.getServer(defaultServer: .production())

    // Length secret key for encrypt content of deal.
    // IMPORTANT: only 64
    static let sharedKeyLength = 64
    
    static let supportEmail = "support@contractus.tech"
    
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""

    static let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""

    static let bundleId = Bundle.main.bundleIdentifier!

    // MARK: - Information URL's

    static let tiersInformationURL: URL = URL(string: "https://contractus.gitbook.io/docs/tiers")!

    static let holderModeURL: URL = URL(string: "https://contractus.gitbook.io/docs/holder-mode")!

    static let faqURL: URL = URL(string: "https://contractus.gitbook.io/docs/faq")!

    static let lockedFundsURL: URL = URL(string: "https://contractus.gitbook.io/docs/faq")!

    static let feesURL: URL = URL(string: "https://contractus.gitbook.io/docs/fees")!

    static let ctusInfoURL: URL = URL(string: "https://contractus.gitbook.io/docs/ctus-token")!
}
