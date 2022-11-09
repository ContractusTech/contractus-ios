//
//  RandomStrings.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation

extension String {
    static func random(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
