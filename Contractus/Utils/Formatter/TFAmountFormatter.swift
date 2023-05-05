//
//  TFAmountFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.08.2022.
//

import Foundation
import ContractusAPI

//
//final class TFAmountFormatter: Formatter {
//
//    var token: Token
//
//    override init() {
//        token = SolanaTokens.unknown
//        super.init()
//    }
//
//    convenience init(token: Token) {
//        self.init()
//        self.token = token
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func string(for obj: Any?) -> String? {
//        guard let string = obj as? String, let amount = token.format(string: string) else { return nil }
//        return AmountFormatter.format(amount: amount, token: token)
//    }
//
//    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
//        obj?.pointee = string.trimmingCharacters(in: .whitespacesAndNewlines) as? AnyObject
//        return true
//    }
//}
