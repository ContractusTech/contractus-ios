import Foundation

public struct CalculateResult: Decodable {
//    public let prices: String
    public let fiatCurrency: String
    public let tokenAmount: Double
    public let tokenPrice: Double
}

public struct CreateUrlResult: Decodable {
    public enum CheckoutType: String, Decodable {
        case nowpayments, advcash
    }
    public let paymentUrl: String
    public let type: CheckoutType
    public let successUrl: String?
    public let failUrl: String?
    public let method: String?
    public let params: [String: String]?
}

public struct AvailableMethodsResult: Decodable {
    public let methods: [CheckoutType]
}

public enum CheckoutType: String, Decodable {
    case nowpayments
    case advcash
    case transak
    case unknown

    public init?(rawValue: String) {
        switch rawValue {
        case Self.nowpayments.rawValue:
            self = .nowpayments
        case Self.transak.rawValue:
            self = .transak
        case Self.advcash.rawValue:
            self = .advcash
        default:
            self = .unknown
        }
    }
}
