//
//  KeyFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import Foundation

struct KeyFormatter {

    static func format(from string: String?, visibleCount: Int = 4) -> String {
        guard let string = string, string.count > visibleCount * 2 else {
            return ""
        }
        let firstPart = string.prefix(visibleCount)
        let lastPart = string.suffix(visibleCount)
        return "\(firstPart)***\(lastPart)"
    }
}
