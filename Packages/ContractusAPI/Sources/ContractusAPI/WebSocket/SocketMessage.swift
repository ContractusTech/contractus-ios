//
//  SocketMessage.swift
//  
//
//  Created by Simon Hudishkin on 28.04.2023.
//

import Foundation

public enum SocketMessage: Decodable {

    enum MessageType: String, Decodable {
        case dealAmountChanged = "DEAL_AMOUNT_CHANGED",
             dealStarted = "DEAL_STARTED",
             dealSigned = "DEAL_SIGNED",
             dealMetaUpdated = "DEAL_META_UPDATED",
             dealResultUpdated = "DEAL_RESULT_UPDATED"
    }

    public struct ObjectId: Decodable {
        let id: String
    }

    public struct DealSigned: Decodable {
        let id: String
        let signer: String
    }

    case dealAmountChanged(ObjectId)
    case dealStarted(ObjectId)
    case dealSigned(DealSigned)
    case dealMetaUpdated(ObjectId)
    case dealResultUpdated(ObjectId)
    case unknown(String)

    enum CodingKeys: CodingKey {
        case type, data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SocketMessage.CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: SocketMessage.CodingKeys.type)
        switch type {
        case .dealAmountChanged:
            let id = try container.decode(Self.ObjectId.self, forKey: SocketMessage.CodingKeys.data)
            self = .dealAmountChanged(id)
        case .dealStarted:
            let id = try container.decode(Self.ObjectId.self, forKey: SocketMessage.CodingKeys.data)
            self = .dealStarted(id)
        case .dealSigned:
            let data = try container.decode(Self.DealSigned.self, forKey: SocketMessage.CodingKeys.data)
            self = .dealSigned(data)
        case .dealMetaUpdated:
            let id = try container.decode(Self.ObjectId.self, forKey: SocketMessage.CodingKeys.data)
            self = .dealMetaUpdated(id)
        case .dealResultUpdated:
            let id = try container.decode(Self.ObjectId.self, forKey: SocketMessage.CodingKeys.data)
            self = .dealResultUpdated(id)
        }
    }
}
