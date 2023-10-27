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

    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
    
    var decimal: String {
        let decimals = Set("0123456789.,")
        return String(self.filter{ decimals.contains($0) })
    }

    var double: Double {
        let value = self.decimal.replacingOccurrences(of: ",", with: ".")
        return Double(value) ?? 0.0
    }

    func filterAmount(decimals: Int) -> String {
        var filtered = self.decimal
        let components = filtered.replacingOccurrences(of: ",", with: ".").components(separatedBy: ".")
        if let fraction = components.last, components.count > 1, fraction.count > decimals {
            filtered = String(filtered.dropLast())
        }
        return filtered
    }
}
