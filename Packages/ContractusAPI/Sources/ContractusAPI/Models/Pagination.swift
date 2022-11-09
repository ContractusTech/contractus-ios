//
//  Pagination.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation

public struct Pagination: Encodable {

    public var skip: Int
    public var take: Int

    public init(skip: Int, take: Int) {
        self.skip = skip
        self.take = take
    }
}
