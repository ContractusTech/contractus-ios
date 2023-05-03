//
//  File.swift
//  
//
//  Created by Simon Hudishkin on 02.02.2023.
//

import Foundation
import BigInt

public enum AmountFormatter {
    
    public static func format(amount: UInt64, decimal: Int, code: String? = nil, local: Locale = .current) -> String {
        return format(amount: BigUInt(amount), decimal: decimal, code: code, local: local)
    }

    public static func format(amount: BigUInt, decimal: Int, code: String? = nil, local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = decimal > 0
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = decimal
        formatter.currencyCode = ""
        formatter.currencySymbol = code ?? ""
        formatter.locale = local
        let amount = Double(amount) / pow(Double(10), Double(decimal))
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? ""
//        if withCode {
//            return String(format: "%@ %@", code, formattedAmount).trimmingCharacters(in: .whitespacesAndNewlines)
//        }
        return formattedAmount
    }

    public static func format(string: String, decimal: Int, code: String? = nil, local: Locale = .current) -> BigUInt? {
        var string = string
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimal)
        formatter.currencyCode = code ?? ""
        formatter.currencySymbol = ""
        formatter.locale = local
        if let groupingSeparator = local.groupingSeparator {
            string = string.replacingOccurrences(of: groupingSeparator, with: "")
        }
        guard let amount = formatter.number(from: string) else { return nil }
        return BigUInt(amount.doubleValue * pow(Double(10), Double(decimal)))
    }


    public static func format(amount: UInt64, token: Token, withCode: Bool = true, local: Locale = .current) -> String {
        return format(amount: BigUInt(amount), decimal: token.decimals, code: withCode ? token.code : nil, local: local)
    }

    public static func format(string: String, token: Token, withCode: Bool = true, local: Locale = .current) -> BigUInt? {
        return format(string: string, decimal: token.decimals, code: withCode ? token.code : nil, local: local)
    }

    public static func format(amount: BigUInt, token: Token, withCode: Bool = true, local: Locale = .current) -> String {
        return format(amount: amount, decimal: token.decimals, code: withCode ? token.code : nil, local: local)
    }
    
}
