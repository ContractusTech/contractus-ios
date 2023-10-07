import Foundation

public struct CalculateResult: Decodable {
//    public let prices: String
    public let fiatCurrency: String
    public let tokenAmount: Double
    public let tokenPrice: Double
}

public struct CreateUrlResult: Decodable {
    public let paymentUrl: String
}
