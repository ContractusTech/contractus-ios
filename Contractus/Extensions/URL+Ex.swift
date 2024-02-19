//
//  Url+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 10.11.2022.
//

import Foundation

extension URL {
    var isImage: Bool {
        mimeTypes[self.lastPathComponent]?.1 == .image
    }

    static func solscanURL(signature: String, isDevnet: Bool = true) -> URL {
        if isDevnet {
            return URL(string: "https://solscan.io/tx/\(signature)?cluster=devnet")!
        }
        return URL(string: "https://solscan.io/tx/\(signature)")!
    }

    static func bscURL(signature: String, isDevnet: Bool = true) -> URL {
        if isDevnet {
            return URL(string: "https://testnet.bscscan.com/tx/\(signature)")!
        }
        return URL(string: "https://bscscan.com/tx/\(signature)")!
    }
}
