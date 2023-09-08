import Foundation

public struct ReferralProgram: Decodable {

    public enum PrizeType: String, Decodable {
        case signup = "SIGNUP",
             applyPromocode = "APPLY_PROMOCODE",
             applyPromocodeReferrer = "APPLY_PROMOCODE_REFERRER",
             unknown
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self = try PrizeType(rawValue: container.decode(RawValue.self)) ?? .unknown
        }
    }

    public struct Prize: Decodable {
        public let type: PrizeType
        public let amount: Amount
        public let price: Amount
        public let applied: Bool
        public let count: Int
        public let description: String?
    }

    public let promocode: String?
    public let referrerCode: String?
    public let prizes: [Prize]
    public let allowApply: Bool
}

public struct ReferralProgramResult: Decodable {
    public let status: TransactionStatus
}
