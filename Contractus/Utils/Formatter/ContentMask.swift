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
}
