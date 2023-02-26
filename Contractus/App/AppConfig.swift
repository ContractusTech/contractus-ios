//
//  AppConfig.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI

enum AppConfig {

    static let serverType: ServerType = ConfigStorage.getServer(defaultServer: .custom(URL(string: "http://localhost:3000/")!))

    // Length secret key for encrypt content of deal.
    // IMPORTANT: only 64
    static let sharedKeyLength = 64
}
