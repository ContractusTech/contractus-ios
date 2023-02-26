//
//  Error.swift
//  
//
//  Created by Simon Hudishkin on 29.07.2022.
//

import Foundation

public struct ServiceError: Codable {

    public struct Validation: Codable {
        public let source: String
        public let keys: [String]
        public var message: String?
    }

    public let statusCode: Int
    public let error: String
    public var message: String?
    public var validation: [String: Validation]?
}


public enum APIClientError: Error, LocalizedError {
    case serviceError(ServiceError),
         commonError(Error),
         unknownError

    public var errorDescription: String? {
        switch self {
        case .commonError(let error):
            return error.localizedDescription
        case .serviceError(let error):
            return error.message ?? error.error
        case .unknownError:
            return "Something wrong"
        }
    }
    
}
