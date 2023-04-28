//
//  Array+Ex.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.02.2023.
//

import Foundation

extension Array {
    public var second: Element? {
        return self[1]
    }

    public var third: Element? {
        return self[2]
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
