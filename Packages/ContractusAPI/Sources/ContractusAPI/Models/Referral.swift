import Foundation

public struct ReferralProgram: Decodable {

    public struct Prize: Decodable {
        public let type: String
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
