//
//  JSDateFormatter.swift
//  
//
//  Created by Simon Hudishkin on 24.05.2023.
//

import Foundation

internal enum APIDateFormatter {

    static private var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    static func parseDate(string: String) -> Date? {
        return Self.formatter.date(from: string)
    }

    static func toString(date: Date) -> String {
        Self.formatter.string(from: date)
    }
}

internal extension Date {
    var asServerString: String {
        return APIDateFormatter.toString(date: self)
    }
}

internal extension String {
    var asDate: Date? {
        return APIDateFormatter.parseDate(string: self)
    }
}
