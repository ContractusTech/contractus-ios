//
//  File 2.swift
//  
//
//  Created by Simon Hudishkin on 05.08.2022.
//

import Foundation

public struct TextContent: Codable {

    public let text: String
    public let md5: String

    public init(text: String, md5: String) {
        self.text = text
        self.md5 = md5
    }

}

public struct DealMetadata: Codable {

    public var content: TextContent?
    public let files: [UploadedFile]

    public init(content: TextContent? = nil, files: [UploadedFile]) {
        self.content = content
        self.files = files
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
