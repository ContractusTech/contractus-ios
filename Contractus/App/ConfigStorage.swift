//
//  ConfigStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.02.2023.
//

import Foundation
import ContractusAPI

final class ConfigStorage {

    enum Keys: String {
        case serverType
    }

    static func getServer(defaultServer: ServerType = .developer()) -> ServerType {
        guard
            let server = UserDefaults.standard.stringArray(forKey: Keys.serverType.rawValue),
            let url = URL(string: server.first ?? ""),
            let version = ServerType.APIVersion(rawValue: server.last ?? "")
        else { return defaultServer }

        return .custom(url, version)
    }

    static func setServer(server: ServerType) {
        let url = server.apiURL.absoluteString
        let version = server.version.rawValue
        UserDefaults.standard.set([url, version], forKey: Keys.serverType.rawValue)
    }
}
