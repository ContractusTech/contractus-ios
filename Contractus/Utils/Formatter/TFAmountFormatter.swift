//
//  TFAmountFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.08.2022.
//

import Foundation
import ContractusAPI


final class TFAmountFormatter: Formatter {

    var currency: Currency = .usdc

    override init() {
        super.init()
    }

    convenience init(currency: Currency) {
        self.init()
        self.currency = currency
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func string(for obj: Any?) -> String? {
        guard let string = obj as? String, let amount = currency.format(string: string) else { return nil }
        return currency.format(amount: amount, withCode: false)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string.trimmingCharacters(in: .whitespacesAndNewlines) as? AnyObject
        return true
    }
}
