//
//  SharePublicKey.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.11.2022.
//

import ContractusAPI

struct SharablePublicKey: Shareable {

    let publicKey: String

    init(shareContent: String) throws {
        self.publicKey = shareContent
    }

    var shareContent: String {
        return publicKey
    }
}
