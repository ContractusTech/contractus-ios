//
//  Double+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.12.2022.
//

import ContractusAPI
import Foundation

extension Double {
    
    func format(for currency: Currency, local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = currency.decimal > 0
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(currency.decimal)
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.locale = local
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
