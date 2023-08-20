import Foundation

public struct ReferralProgram: Decodable {

    public enum PrizeType: String, Decodable {
        case signup = "SIGNUP"
        case applyPromocode = "APPLY_PROMOCODE"
//        case applyPromocodeReferrer = "APPLY_PROMOCODE_REFERRER"
        case applyPromocodeReferrer = "APPLY_PROMOCODE_REFFERER"
    }

    public struct Prize: Decodable {
        public let type: PrizeType
        public let amount: Amount
        public let applied: Bool
        public let count: Int
        public let description: String?
    }

    public let promocode: String?
    public let referrerCode: String?
    public let prizes: [Prize]
}

public struct ReferralProgramResult: Decodable {
    public let status: TransactionStatus
}
