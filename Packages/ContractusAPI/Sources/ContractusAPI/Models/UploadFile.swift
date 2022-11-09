//
//  UploadFile.swift
//  
//
//  Created by Simon Hudishkin on 04.08.2022.
//

import Foundation


public struct UploadFile: Encodable {
    public let md5: String
    public let data: Data
    public let fileName: String
    public let mimeType: String

    public init(md5: String, data: Data, fileName: String, mimeType: String) {
        self.md5 = md5
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

}

public struct UploadedFile: Codable {
    public let md5: String
    public let url: URL
}
