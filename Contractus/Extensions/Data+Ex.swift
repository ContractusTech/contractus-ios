//
//  Data+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 22.11.2022.
//

import Foundation
import Base58Swift

extension Data {
    func toBase58() -> String {
        return Base58.base58Encode(self.bytes)
    }
}
