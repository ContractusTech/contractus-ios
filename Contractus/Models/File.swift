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

    static func asPNGImage(_ image: UIImage, path: URL) -> RawFile {
        return RawFile(data: image.pngData()!, name: path.lastPathComponent, mimeType: mimeTypes["png"]!)
    }

}


protocol RawedFile {
    func rawFile(with name: String?) -> RawFile
}
