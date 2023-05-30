//
//  Date+Formatter.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.05.2023.
//

import Foundation


extension Date {

    func asDateFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("dd MMMM YYYY")
        return formatter.string(from: self)
    }
}
