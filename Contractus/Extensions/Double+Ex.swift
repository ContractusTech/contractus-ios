//
//  Double+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.12.2022.
//

import ContractusAPI
import Foundation

extension Double {
    
    func format(for token: Token, local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = token.decimal > 0
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = token.decimal
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.locale = local
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }

    func formatAsPercent(local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = local
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
