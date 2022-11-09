//
//  ServiceFactory.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.09.2022.
//

import Foundation
import SolanaSwift

final class ServiceFactory {

    // MARK: - Shared
    static let shared = ServiceFactory()

    func makeTransactionSign() -> TransactionSignService {
        return SolanaTransactionSignServiceImpl()
    }
}
