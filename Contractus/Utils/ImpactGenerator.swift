//
//  ImpactGenerator.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.11.2022.
//

import UIKit

enum ImpactGenerator {
    static func soft() {
        let impactMed = UIImpactFeedbackGenerator(style: .soft)
        impactMed.impactOccurred()
    }

    static func light() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }

    static func rigid() {
        let impactMed = UIImpactFeedbackGenerator(style: .rigid)
        impactMed.impactOccurred(intensity: 0.6)
    }
}
