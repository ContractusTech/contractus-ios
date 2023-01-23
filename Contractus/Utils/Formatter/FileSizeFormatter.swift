//
//  FileSizeFormatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 21.11.2022.
//

import Foundation


final class FileSizeFormatter {

    static let shared = FileSizeFormatter()

    private let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter
    }()

    func format(_ countBytes: Int64) -> String {
        return formatter.string(fromByteCount: countBytes)
    }

    func format(_ countBytes: Int) -> String {
        format(Int64(countBytes))
    }
}
