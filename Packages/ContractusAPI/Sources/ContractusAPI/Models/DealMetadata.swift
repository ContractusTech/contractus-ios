//
//  File 2.swift
//  
//
//  Created by Simon Hudishkin on 05.08.2022.
//

import Foundation

public struct TextContent: Codable, Equatable {

    public let text: String
    public let md5: String

    public init(text: String, md5: String) {
        self.text = text
        self.md5 = md5
    }

}

public struct MetadataFile: Codable, Equatable {

    enum CodingKeys: CodingKey {
        case md5, url, name, encrypted, size
    }
    
    public let md5: String
    public let url: URL
    public let name: String
    public let encrypted: Bool
    public let size: Int64

    public init(md5: String, url: URL, name: String, encrypted: Bool, size: Int64) {
        self.md5 = md5
        self.url = url
        self.name = name
        self.encrypted = encrypted
        self.size = size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.md5 = try container.decode(String.self, forKey: .md5)
        self.url = URL(string: try container.decode(String.self, forKey: .url))!

        self.name = try container.decode(String.self, forKey: .name)
        self.encrypted = try container.decode(Bool.self, forKey: .encrypted)
        self.size = try container.decode(Int64.self, forKey: .size)
    }
}

public struct DealMetadata: Codable, Equatable {

    enum CodingKeys: CodingKey {
        case content, files
    }

    public var content: TextContent?
    public let files: [MetadataFile]

    public init(content: TextContent? = nil, files: [MetadataFile]) {
        self.content = content
        self.files = files
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try? container.decodeIfPresent(TextContent.self, forKey: .content)
        self.files = try container.decode([MetadataFile].self, forKey: .files)
    }

}

public struct UpdateDealMetadata: Codable {

    public let meta: DealMetadata
    public let updatedAt: Date
    public let force: Bool

    public init(meta: DealMetadata, updatedAt: Date, force: Bool) {
        self.meta = meta
        self.updatedAt = updatedAt
        self.force = force
    }

}
