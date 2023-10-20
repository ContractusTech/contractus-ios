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
