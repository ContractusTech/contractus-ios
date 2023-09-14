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
        SolanaTransactionSignServiceImpl()
    }

    func makeBackupStorage() -> BackupStorage {
        iCloudBackupStorage()
    }

    func makeAccountStorage() -> AccountStorage {
        KeychainAccountStorage()
    }

    func makeIdService() -> IdentifierService {
        IdentifierService(authStorage: KeychainAuthStorage())
    }
    
    func makeOnboardingService() -> OnboardingService {
        OnboardingServiceImpl.shared
    }
}
