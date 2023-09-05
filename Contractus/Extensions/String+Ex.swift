import Foundation
import SwiftUI

extension String {
    var imageByFileName: Image {
        switch MimeType(path: self).fileGroup {
        case .archive:
            return Image(systemName: "doc.zipper")
        case .audio:
            return Image(systemName: "music.note")
        case .code:
            return Image(systemName: "doc.plaintext")
        case .doc:
            return Image(systemName: "doc.text")
        case .image:
            return Image(systemName: "photo.fill")
        case .text:
            return Image(systemName: "doc.plaintext")
        case .video:
            return Image(systemName: "video.fill")
        case .web:
            return Image(systemName: "doc.plaintext")
        case .unknown:
            return Image(systemName: "doc")
        }
    }
}