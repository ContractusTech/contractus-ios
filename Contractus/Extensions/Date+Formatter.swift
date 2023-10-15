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
        
    public var relativeDateFormatted: String {
        let dcf: DateComponentsFormatter = DateComponentsFormatter()
        dcf.includesApproximationPhrase = false
        dcf.includesTimeRemainingPhrase = false
        dcf.allowsFractionalUnits = false
        dcf.maximumUnitCount = 1
        dcf.unitsStyle = .abbreviated
        dcf.allowedUnits = [.second, .minute, .hour, .day, .month, .year]
        return dcf.string(from: self, to: Date()) ?? ""
    }
    
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    static func fullRelativeDateFormatted(from: Date?, to: Date?) -> String {
        guard let from = from, let to = to else { return "" }
        let dcf: DateComponentsFormatter = DateComponentsFormatter()
        dcf.includesApproximationPhrase = false
        dcf.includesTimeRemainingPhrase = false
        dcf.allowsFractionalUnits = false
        dcf.maximumUnitCount = 2
        dcf.unitsStyle = .full
        dcf.allowedUnits = [.second, .minute, .hour, .day, .month, .year]
        return dcf.string(from: from, to: to) ?? ""
    }
}
