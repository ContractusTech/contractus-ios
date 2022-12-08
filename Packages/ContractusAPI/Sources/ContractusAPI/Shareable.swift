//
//  Shareable.swift
//  
//
//  Created by Simon Hudishkin on 06.10.2022.
//

import Foundation

public enum ShareableError: Error {
    case invalidContent
}

public protocol Shareable {
    init(shareContent: String) throws
    var shareContent: String { get }
}
