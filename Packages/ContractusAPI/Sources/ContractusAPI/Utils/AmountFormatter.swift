//
//  AmountFormatter.swift
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
        formatter.roundingMode = .halfDown
        formatter.maximumFractionDigits = min(decimal, 5)
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.locale = local
        let amount = Double(amount) / pow(Double(10), Double(decimal))
        let formattedAmount = (formatter.string(from: NSNumber(value: amount)) ?? "").trimmingCharacters(in: .whitespaces)
        return "\(formattedAmount) \(code ?? "")".trimmingCharacters(in: .whitespaces)
    }

    public static func format(string: String, decimal: Int, code: String? = nil, local: Locale = .current) -> BigUInt? {
        var string = string
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimal)
        formatter.currencyCode = ""
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

    public static func formatShort(amount: BigUInt, token: Token, withCode: Bool = true, local: Locale = .current) -> String {
        let computedAmount = Double(amount) / pow(Double(10), Double(token.decimals))

        if computedAmount < 0.001 && computedAmount > 0 {
            return "less"
        }
        if computedAmount < 1 {
            return format(amount: amount, decimal: token.decimals, code: withCode ? token.code : nil, local: local)
        }

        let numFormatter = NumberFormatter()

        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [(0, 1, ""),
                                            (1000.0, 1000.0, "k"),
                                            (1_000_000.0, 1_000_000.0, "m"),
                                            (100_000_000.0, 1_000_000_000.0, "b")]
                                            // Can add more !

        let startValue = computedAmount
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if (startValue < tmpAbbreviation.threshold) {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        } ()

        var maxFractionDigits = 1
        switch computedAmount {
        case _ where computedAmount < 100_000:
            maxFractionDigits = 1
        case _ where computedAmount < 1_000_000:
            maxFractionDigits = 0
        case _ where computedAmount >= 1_000_000:
            maxFractionDigits = 2
        default:
            maxFractionDigits = 1
        }

        let value = computedAmount / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = maxFractionDigits

        let formattedAmount = numFormatter.string(from: NSNumber(value: value))!

        if withCode {
            return String(format: "%@ %@", formattedAmount, token.code).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return formattedAmount.trimmingCharacters(in: .whitespaces)
        }
    }
}
