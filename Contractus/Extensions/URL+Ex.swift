//
//  Url+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 10.11.2022.
//

import Foundation

extension URL {
    var isImage: Bool {
        mimeTypes[self.lastPathComponent]?.contains("image") ?? false
    }
}
