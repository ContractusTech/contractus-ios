//
//  ShareDealData.swift
//  
//
//  Created by Simon Hudishkin on 05.10.2022.
//

import Foundation

fileprivate let SEPARATOR = "^"

public struct ShareableDeal: Shareable, Equatable {

    public enum ShareableCommand: String, Equatable {
        case shareDealSecret = "sds"
    }

    public enum ShareDealDataError: Error {
        case invalidContent
    }

    public let id: String
    public let secretBase64: String
    public let command: ShareableCommand

    public init(dealId: String, secretBase64: String, command: Self.ShareableCommand = .shareDealSecret) {
        self.id = dealId
        self.secretBase64 = secretBase64
        self.command = command
    }

    public init(shareContent: String) throws {
        guard let base64Data = shareContent.data(using: .utf8),
              let data = Data(base64Encoded: base64Data),
        let content = String(data: data, encoding: .utf8) else {
            throw ShareDealDataError.invalidContent
        }
        let parts =  content.components(separatedBy: SEPARATOR)
        guard
            let commandValue =  parts.first,
            let command = ShareableCommand(rawValue: commandValue)
        else {
            throw Self.ShareDealDataError.invalidContent
        }
        guard parts.count == 3 else {
            throw Self.ShareDealDataError.invalidContent
        }

        self.id = parts[1]
        self.secretBase64 = parts[2]
        self.command = command
    }

    public var shareContent: String {
        let string = "\(command.rawValue)\(SEPARATOR)\(id)\(SEPARATOR)\(secretBase64)"
        return string.data(using: .utf8)!.base64EncodedString()
    }
}
