//
//  File.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import Foundation
import UIKit


struct RawFile {
    let data: Data
    let name: String
    let mimeType: String
}

protocol RawedFile {
    func rawFile(with name: String?) -> RawFile
}

extension RawFile: Equatable {

    static func fromImage(_ image: UIImage, path: URL) -> RawFile? {
        if let data = image.rotate(radians: 0)?.pngData() {
            return RawFile(data: data, name: path.lastPathComponent, mimeType: mimeTypes["png"]!.0)
        }
        return nil
    }

    var isImage: Bool {
        mimeType.contains("image")
    }

    var formattedSize: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(data.count))
    }

    var isLargeForEncrypting: Bool {
        // TODO: - Value for test, may be need change
        (Int64(data.count) / 1048576) > 2
    }
}
