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
        case production, developer, local, custom
    }

    static func getServer(defaultServer: ServerType = .developer()) -> ServerType {
        guard
            let server = UserDefaults.standard.stringArray(forKey: Keys.serverType.rawValue),
            let url = URL(string: server.first ?? ""),
            let wsUrl = URL(string: server.second ?? ""),
            let version = ServerType.APIVersion(rawValue: server.third ?? ""),
            let type = ServerTypeString(rawValue: server.last ?? "")
        else { return defaultServer }

        switch type {
        case .production:
            return .production(version)
        case .developer:
            return .developer(version)
        case .local:
            return .local()
        case .custom:
            return .custom(api: url, ws: wsUrl)
        }
    }

    static func setServer(server: ServerType) {
        let url = server.apiURL.absoluteString
        let wsUrl = server.wsServer.absoluteString
        let version = server.version.rawValue
        let type = server.title.lowercased()
        UserDefaults.standard.set([url, wsUrl, version, type], forKey: Keys.serverType.rawValue)
    }
}
