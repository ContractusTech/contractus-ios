//
//  KeyFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import Foundation

struct ContentMask {

    static func mask(from string: String?, visibleCount: Int = 4, maskCount: Int = 3) -> String {
        if visibleCount <= 0 {
            return string ?? ""
        }
        guard let string = string else {
            return ""
        }
        var _visibleCount = visibleCount
        var _maskCount = maskCount
        if string.count <= visibleCount * 2 {
            _visibleCount = string.count / 3
        }
        if _maskCount <= 0 {
            _maskCount = string.count - _visibleCount
        }
        let firstPart = string.prefix(_visibleCount)
        let lastPart = string.suffix(_visibleCount)
        let maskString = (String)(repeating: "*", count: _maskCount)
        return "\(firstPart)\(maskString)\(lastPart)"
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
