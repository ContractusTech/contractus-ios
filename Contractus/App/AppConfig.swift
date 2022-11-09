//
//  AppConfig.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI

enum AppConfig {

    static let serverType: ServerType = .custom("http://localhost:3000/v1")

    // Length secret key for encrypt content of deal.
    // IMPORTANT: only 64
    static let sharedKeyLength = 64
}
