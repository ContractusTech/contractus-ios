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
    
    enum ServerTypeString: String {
        case production, developer, custom
    }

    static func getServer(defaultServer: ServerType = .developer()) -> ServerType {
        guard
            let server = UserDefaults.standard.stringArray(forKey: Keys.serverType.rawValue),
            let url = URL(string: server.first ?? ""),
            let version = ServerType.APIVersion(rawValue: server.second ?? ""),
            let type = ServerTypeString(rawValue: server.last ?? "")
        else { return defaultServer }

        switch type {
        case .production:
            return .production()
        case .developer:
            return .developer()
        case .custom:
            return .custom(url, version)
        }
    }

    static func setServer(server: ServerType) {
        let url = server.apiURL.absoluteString
        let version = server.version.rawValue
        let type = server.title.lowercased()
        UserDefaults.standard.set([url, version, type], forKey: Keys.serverType.rawValue)
    }
}
