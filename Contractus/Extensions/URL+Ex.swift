//
//  Url+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 10.11.2022.
//

import Foundation

extension URL {
    var isImage: Bool {
        mimeTypes[self.lastPathComponent]?.contains("image") ?? false
    }

    static func solscanURL(signature: String, isDevnet: Bool = true) -> URL {
        if isDevnet {
            return URL(string: "https://solscan.io/tx/\(signature)?cluster=devnet")!
        }
        return URL(string: "https://solscan.io/tx/\(signature)")!
    }
}
