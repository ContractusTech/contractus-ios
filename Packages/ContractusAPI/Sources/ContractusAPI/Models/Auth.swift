import Foundation

public struct DeviceMessage: Decodable {
    public let identifier: String
    public let message: String
    public let expiredAt: Date

    enum CodingKeys: CodingKey {
        case identifier
        case message
        case expiredAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.message = try container.decode(String.self, forKey: .message)
        let expired = try container.decode(String.self, forKey: .expiredAt)
        self.expiredAt = expired.asDate!
    }
}
