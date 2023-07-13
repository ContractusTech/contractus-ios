//
//  AppConfig.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI

enum AppConfig {

    static let serverType: ServerType = ConfigStorage.getServer(defaultServer: .developer())

    // Length secret key for encrypt content of deal.
    // IMPORTANT: only 64
    static let sharedKeyLength = 64
    
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    static let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""

    static let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? ""

    static let tiersInformationURL: URL = URL(string: "https://contractus.tech")! // TODO: - Need change

    static let bundleId = Bundle.main.bundleIdentifier!
}
