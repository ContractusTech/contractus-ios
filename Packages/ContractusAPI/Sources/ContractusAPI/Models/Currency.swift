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
    public let decimals: UInt8

    public init(code: String, symbol: String, name: String, decimals: UInt8) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
    }
}

public extension Currency {

    static func from(code: String) -> Currency {
        availableCurrencies.first(where: {$0.code == code }) ?? defaultCurrency
    }
    
    func format(amount: UInt64, withCode: Bool = true, local: Locale = Locale(identifier: "en")) -> String {
        return format(amount: BigUInt(amount), withCode: withCode, local: local)
    }

    func format(amount: BigUInt, withCode: Bool = true, local: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = decimals > 0
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimals)
        formatter.currencyCode = ""
        formatter.currencySymbol = withCode ? self.symbol : ""
        formatter.locale = local
        let amount = Double(amount) / pow(Double(10), Double(decimals))
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? ""
        return formattedAmount
    }

    func format(string: String, local: Locale = Locale(identifier: "en")) -> BigUInt? {
        var string = string
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimals)
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.locale = local
        if let groupingSeparator = local.groupingSeparator {
            string = string.replacingOccurrences(of: groupingSeparator, with: "")
        }
        guard let amount = formatter.number(from: string) else { return nil }
        return BigUInt(amount.doubleValue * pow(Double(10), Double(decimals)))
    }

    func format(double: Double, withCode: Bool, local: Locale = Locale(identifier: "en")) -> String? {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(decimals)
        formatter.currencyCode = ""
        formatter.currencySymbol = withCode ? self.symbol : ""
        formatter.locale = local
        return formatter.string(from: double as NSNumber)
    }

    func format(double: Double, local: Locale = Locale(identifier: "en")) -> String? {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = Int(2)
        formatter.currencyCode = ""
        formatter.currencySymbol = self.symbol
        formatter.locale = local
        return formatter.string(from: double as NSNumber)
    }
}

extension Currency: Equatable {
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.code == rhs.code // TODO: - add compare other fields if needed
    }

}


extension Currency {

    public static let defaultCurrency: Currency = .USD
    
    public static let availableCurrencies: [Currency] = [.USD, .AUD, .BRL, .CAD, .CHF, .CLP, .CNY, .CZK, .DKK, .EUR, .GBP, .HKD, .HUF, .IDR, .ILS, .INR, .JPY, .KRW, .MXN, .MYR, .NOK, .NZD, .PHP, .PKR, .PLN, .RUB, .SEK, .SGD, .THB, .TRY, .TWD, .ZAR, .AED, .BGN, .HRK, .MUR, .RON, .ISK, .NGN, .COP, .ARS, .PEN, .VND, .UAH, .BOB, .ALL, .AMD, .AZN, .BAM, .BDT, .BHD, .BMD, .BYN, .CRC, .CUP, .DOP, .DZD, .EGP, .GEL, .GHS, .GTQ, .HNL, .IQD, .IRR, .JMD, .JOD, .KES, .KGS, .KHR, .KWD, .KZT, .LBP, .LKR, .MAD, .MDL, .MKD, .MMK, .MNT, .NAD, .NIO, .NPR, .OMR, .PAB, .QAR, .RSD, .SAR, .SSP, .TND, .TTD, .UGX, .UYU, .UZS, .VES]

    public static let USD = Currency(code: "USD", symbol: "$", name: "United States Dollar", decimals: 6)
    public static let AUD = Currency(code: "AUD", symbol: "$", name: "Australian Dollar", decimals: 6)
    public static let BRL = Currency(code: "BRL", symbol: "R$", name: "Brazilian Real", decimals: 6)
    public static let CAD = Currency(code: "CAD", symbol: "$", name: "Canadian Dollar", decimals: 6)
    public static let CHF = Currency(code: "CHF", symbol: "Fr", name: "Swiss Franc", decimals: 6)
    public static let CLP = Currency(code: "CLP", symbol: "$", name: "Chilean Peso", decimals: 6)
    public static let CNY = Currency(code: "CNY", symbol: "¥", name: "Chinese Yuan", decimals: 6)
    public static let CZK = Currency(code: "CZK", symbol: "Kč", name: "Czech Koruna", decimals: 6)
    public static let DKK = Currency(code: "DKK", symbol: "kr", name: "Danish Krone", decimals: 6)
    public static let EUR = Currency(code: "EUR", symbol: "€", name: "Euro", decimals: 6)
    public static let GBP = Currency(code: "GBP", symbol: "£", name: "Pound Sterling", decimals: 6)
    public static let HKD = Currency(code: "HKD", symbol: "$", name: "Hong Kong Dollar", decimals: 6)
    public static let HUF = Currency(code: "HUF", symbol: "Ft", name: "Hungarian Forint", decimals: 6)
    public static let IDR = Currency(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", decimals: 6)
    public static let ILS = Currency(code: "ILS", symbol: "₪", name: "Israeli New Shekel", decimals: 6)
    public static let INR = Currency(code: "INR", symbol: "₹", name: "Indian Rupee", decimals: 6)
    public static let JPY = Currency(code: "JPY", symbol: "¥", name: "Japanese Yen", decimals: 6)
    public static let KRW = Currency(code: "KRW", symbol: "₩", name: "South Korean Won", decimals: 6)
    public static let MXN = Currency(code: "MXN", symbol: "$", name: "Mexican Peso", decimals: 6)
    public static let MYR = Currency(code: "MYR", symbol: "RM", name: "Malaysian Ringgit", decimals: 6)
    public static let NOK = Currency(code: "NOK", symbol: "kr", name: "Norwegian Krone", decimals: 6)
    public static let NZD = Currency(code: "NZD", symbol: "$", name: "New Zealand Dollar", decimals: 6)
    public static let PHP = Currency(code: "PHP", symbol: "₱", name: "Philippine Peso", decimals: 6)
    public static let PKR = Currency(code: "PKR", symbol: "₨", name: "Pakistani Rupee", decimals: 6)
    public static let PLN = Currency(code: "PLN", symbol: "zł", name: "Polish Złoty", decimals: 6)
    public static let RUB = Currency(code: "RUB", symbol: "₽", name: "Russian Ruble", decimals: 6)
    public static let SEK = Currency(code: "SEK", symbol: "kr", name: "Swedish Krona", decimals: 6)
    public static let SGD = Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar", decimals: 6)
    public static let THB = Currency(code: "THB", symbol: "฿", name: "Thai Baht", decimals: 6)
    public static let TRY = Currency(code: "TRY", symbol: "₺", name: "Turkish Lira", decimals: 6)
    public static let TWD = Currency(code: "TWD", symbol: "NT$", name: "New Taiwan Dollar", decimals: 6)
    public static let ZAR = Currency(code: "ZAR", symbol: "R", name: "South African Rand", decimals: 6)
    public static let AED = Currency(code: "AED", symbol: "د.إ", name: "United Arab Emirates Dirham", decimals: 6)
    public static let BGN = Currency(code: "BGN", symbol: "лв", name: "Bulgarian Lev", decimals: 6)
    public static let HRK = Currency(code: "HRK", symbol: "kn", name: "Croatian Kuna", decimals: 6)
    public static let MUR = Currency(code: "MUR", symbol: "₨", name: "Mauritian Rupee", decimals: 6)
    public static let RON = Currency(code: "RON", symbol: "lei", name: "Romanian Leu", decimals: 6)
    public static let ISK = Currency(code: "ISK", symbol: "kr", name: "Icelandic Króna", decimals: 6)
    public static let NGN = Currency(code: "NGN", symbol: "₦", name: "Nigerian Naira", decimals: 6)
    public static let COP = Currency(code: "COP", symbol: "$", name: "Colombian Peso", decimals: 6)
    public static let ARS = Currency(code: "ARS", symbol: "$", name: "Argentine Peso", decimals: 6)
    public static let PEN = Currency(code: "PEN", symbol: "S/.", name: "Peruvian Sol", decimals: 6)
    public static let VND = Currency(code: "VND", symbol: "₫", name: "Vietnamese Dong", decimals: 6)
    public static let UAH = Currency(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia", decimals: 6)
    public static let BOB = Currency(code: "BOB", symbol: "Bs.", name: "Bolivian Boliviano", decimals: 6)
    public static let ALL = Currency(code: "ALL", symbol: "L", name: "Albanian Lek", decimals: 6)
    public static let AMD = Currency(code: "AMD", symbol: "֏", name: "Armenian Dram", decimals: 6)
    public static let AZN = Currency(code: "AZN", symbol: "₼", name: "Azerbaijani Manat", decimals: 6)
    public static let BAM = Currency(code: "BAM", symbol: "KM", name: "Bosnia-Herzegovina Convertible Mark", decimals: 6)
    public static let BDT = Currency(code: "BDT", symbol: "৳", name: "Bangladeshi Taka", decimals: 6)
    public static let BHD = Currency(code: "BHD", symbol: ".د.ب", name: "Bahraini Dinar", decimals: 6)
    public static let BMD = Currency(code: "BMD", symbol: "$", name: "Bermudan Dollar", decimals: 6)
    public static let BYN = Currency(code: "BYN", symbol: "Br", name: "Belarusian Ruble", decimals: 6)
    public static let CRC = Currency(code: "CRC", symbol: "₡", name: "Costa Rican Colón", decimals: 6)
    public static let CUP = Currency(code: "CUP", symbol: "$", name: "Cuban Peso", decimals: 6)
    public static let DOP = Currency(code: "DOP", symbol: "$", name: "Dominican Peso", decimals: 6)
    public static let DZD = Currency(code: "DZD", symbol: "د.ج", name: "Algerian Dinar", decimals: 6)
    public static let EGP = Currency(code: "EGP", symbol: "£", name: "Egyptian Pound", decimals: 6)
    public static let GEL = Currency(code: "GEL", symbol: "₾", name: "Georgian Lari", decimals: 6)
    public static let GHS = Currency(code: "GHS", symbol: "₵", name: "Ghanaian Cedi", decimals: 6)
    public static let GTQ = Currency(code: "GTQ", symbol: "Q", name: "Guatemalan Quetzal", decimals: 6)
    public static let HNL = Currency(code: "HNL", symbol: "L", name: "Honduran Lempira", decimals: 6)
    public static let IQD = Currency(code: "IQD", symbol: "ع.د", name: "Iraqi Dinar", decimals: 6)
    public static let IRR = Currency(code: "IRR", symbol: "﷼", name: "Iranian Rial", decimals: 6)
    public static let JMD = Currency(code: "JMD", symbol: "$", name: "Jamaican Dollar", decimals: 6)
    public static let JOD = Currency(code: "JOD", symbol: "د.ا", name: "Jordanian Dinar", decimals: 6)
    public static let KES = Currency(code: "KES", symbol: "Sh", name: "Kenyan Shilling", decimals: 6)
    public static let KGS = Currency(code: "KGS", symbol: "с", name: "Kyrgystani Som", decimals: 6)
    public static let KHR = Currency(code: "KHR", symbol: "៛", name: "Cambodian Riel", decimals: 6)
    public static let KWD = Currency(code: "KWD", symbol: "د.ك", name: "Kuwaiti Dinar", decimals: 6)
    public static let KZT = Currency(code: "KZT", symbol: "₸", name: "Kazakhstani Tenge", decimals: 6)
    public static let LBP = Currency(code: "LBP", symbol: "ل.ل", name: "Lebanese Pound", decimals: 6)
    public static let LKR = Currency(code: "LKR", symbol: "Rs", name: "Sri Lankan Rupee", decimals: 6)
    public static let MAD = Currency(code: "MAD", symbol: "د.م.", name: "Moroccan Dirham", decimals: 6)
    public static let MDL = Currency(code: "MDL", symbol: "L", name: "Moldovan Leu", decimals: 6)
    public static let MKD = Currency(code: "MKD", symbol: "ден", name: "Macedonian Denar", decimals: 6)
    public static let MMK = Currency(code: "MMK", symbol: "Ks", name: "Myanma Kyat", decimals: 6)
    public static let MNT = Currency(code: "MNT", symbol: "₮", name: "Mongolian Tugrik", decimals: 6)
    public static let NAD = Currency(code: "NAD", symbol: "$", name: "Namibian Dollar", decimals: 6)
    public static let NIO = Currency(code: "NIO", symbol: "C$", name: "Nicaraguan Córdoba", decimals: 6)
    public static let NPR = Currency(code: "NPR", symbol: "₨", name: "Nepalese Rupee", decimals: 6)
    public static let OMR = Currency(code: "OMR", symbol: "ر.ع.", name: "Omani Rial", decimals: 6)
    public static let PAB = Currency(code: "PAB", symbol: "B/.", name: "Panamanian Balboa", decimals: 6)
    public static let QAR = Currency(code: "QAR", symbol: "ر.ق", name: "Qatari Rial", decimals: 6)
    public static let RSD = Currency(code: "RSD", symbol: "дин.", name: "Serbian Dinar", decimals: 6)
    public static let SAR = Currency(code: "SAR", symbol: "ر.س", name: "Saudi Riyal", decimals: 6)
    public static let SSP = Currency(code: "SSP", symbol: "£", name: "South Sudanese Pound", decimals: 6)
    public static let TND = Currency(code: "TND", symbol: "د.ت", name: "Tunisian Dinar", decimals: 6)
    public static let TTD = Currency(code: "TTD", symbol: "$", name: "Trinidad and Tobago Dollar", decimals: 6)
    public static let UGX = Currency(code: "UGX", symbol: "Sh", name: "Ugandan Shilling", decimals: 6)
    public static let UYU = Currency(code: "UYU", symbol: "$", name: "Uruguayan Peso", decimals: 6)
    public static let UZS = Currency(code: "UZS", symbol: "so'm", name: "Uzbekistan Som", decimals: 6)
    public static let VES = Currency(code: "VES", symbol: "Bs.", name: "Sovereign Bolivar", decimals: 6)
}
