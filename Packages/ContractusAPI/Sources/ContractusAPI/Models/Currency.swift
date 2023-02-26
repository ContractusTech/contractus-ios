//
//  Currency.swift
//  
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import Foundation
import BigInt

public struct Currency: Codable {

    public let code: String
    public let symbol: String
    public let name: String
    public let decimal: UInt8

    public init(code: String, symbol: String, name: String, decimal: UInt8) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.decimal = decimal
    }
}

public extension Currency {

    static let availableCurrencies: [Currency] = [ .usd ]

    static let usd = Currency(code: "USD", symbol: "$", name: "Dollar", decimal: 2)

    static func from(code: String) -> Currency {
        if let currecny = availableCurrencies.first(where: {$0.code == code }) {
            return currecny
        }
        return Currency(code: code, symbol: "", name: "Unknown", decimal: 0)
    }
    
    func format(amount: UInt64, withCode: Bool = true, local: Locale = Locale(identifier: "en")) -> String {
        return format(amount: BigUInt(amount), withCode: withCode, local: local)
    }

    func format(amount: BigUInt, withCode: Bool = true, local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = decimal > 0
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimal)
        formatter.currencyCode = ""
        formatter.currencySymbol = withCode ? self.symbol : ""
        formatter.locale = local
        let amount = Double(amount) / pow(Double(10), Double(decimal))
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? ""
        return formattedAmount
    }

    func format(string: String, local: Locale = Locale(identifier: "en")) -> BigUInt? {
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

    func format(double: Double, withCode: Bool, local: Locale = Locale(identifier: "en")) -> String? {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimal)
        formatter.currencyCode = ""
        formatter.currencySymbol = withCode ? self.symbol : ""
        formatter.locale = local
        return formatter.string(from: double as NSNumber)
    }
}

extension Currency: Equatable {
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.code == rhs.code // TODO: - add compare other fields if needed
    }

}
