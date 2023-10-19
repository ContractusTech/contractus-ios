//
//  KeyFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import Foundation

struct ContentMask {

    static func mask(from string: String?, visibleCount: Int = 4) -> String {
        if visibleCount <= 0 {
            return string ?? ""
        }
        guard let string = string, string.count > visibleCount * 2 else {
            return ""
        }
        let firstPart = string.prefix(visibleCount)
        let lastPart = string.suffix(visibleCount)
        return "\(firstPart)***\(lastPart)"
    }

    static func maskAll(_ string: String?) -> String {
        guard let string = string else {
            return ""
        }
        return String(repeating: "*", count: string.count)
    }

    static func maskContent(_ length: Int = 10) -> String {
        return String(repeating: "*", count: length)
    }
}
