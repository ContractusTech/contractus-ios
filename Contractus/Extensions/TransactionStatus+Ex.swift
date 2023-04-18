//
//  TransactionStatus+Ex.swift
//  Contractus
//
//  Created by Simon Hudishkin on 18.04.2023.
//

import Foundation
import ContractusAPI

extension TransactionStatus {
    var title: String {
        switch self {
        case .error:
            return R.string.localizable.transactionSignStatusesError()
        case .finished:
            return R.string.localizable.transactionSignStatusesDone()
        case .new:
            return R.string.localizable.transactionSignStatusesNeedSign()
        case .processing:
            return R.string.localizable.transactionSignStatusesProcessing()
        }
    }
}
