//
//  MainViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.08.2022.
//

import Foundation
import ContractusAPI
import SolanaSwift
import Combine

enum MainInput {
    case load
}

struct MainState {
    var account: SolanaSwift.Account
    var balance: Balance?
    var deals: [ContractusAPI.Deal] = []
}

final class MainViewModel: ViewModel {

    @Published private(set) var state: MainState

    private var accountAPIService: ContractusAPI.AccountService?
    private var dealsAPIService: ContractusAPI.DealsService?
    private var pagination = ContractusAPI.Pagination(skip: 0, take: 100)
    private var store = Set<AnyCancellable>()

    init(
        account: SolanaSwift.Account,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?)
    {
        self.state = MainState(account: account)
        self.accountAPIService = accountAPIService
        self.dealsAPIService = dealsAPIService
    }

    func trigger(_ input: MainInput, after: AfterTrigger? = nil) {
        switch input {
        case .load:
            Task {
                let deals = try? await loadDeals()
                let balance = try? await loadBalance()

                await MainActor.run {
                    self.state.balance = balance
                    self.state.deals = deals ?? []
                    after?()
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadDeals() async throws -> [Deal] {
        try await withCheckedThrowingContinuation { continues in
            dealsAPIService?.getDeals(pagination: pagination, completion: { result in
                switch result {
                case .success(let deals):
                    continues.resume(returning: deals)
                case .failure(let error):
                    continues.resume(throwing: error)
                }
            })
        }
    }

    private func loadBalance() async throws -> Balance {
        try await withCheckedThrowingContinuation { continues in
            accountAPIService?.getBalance(completion: { result in
                switch result {
                case .failure(let error):
                    continues.resume(throwing: error)
                case .success(let balance):
                    continues.resume(returning: balance)
                }
            })
        }
    }

    private func createDeal(role: OwnerRole) {
        guard let dealsAPIService = dealsAPIService else { return }
        let key = String.random(length: AppConfig.sharedKeyLength)

        guard let sharedParts = try? SSS.createShares(data: [UInt8](key.utf8), n: 2, k: 2), let secretKey = sharedParts.first?.toBase64() else {
            return
        }

        Crypto.encrypt(message: key, with: state.account.secretKey)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure:
                    break
                case .finished:
                    break
                }

            } receiveValue: { encryptedSecretKey in
                let deal = NewDeal(
                    role: role,
                    encryptedSecretKey: encryptedSecretKey.base64EncodedString(),
                    secretKeyHash: Crypto.sha3(data: encryptedSecretKey),
                    sharedKey: secretKey)

                dealsAPIService.create(
                    data: deal, completion: { result in
                    switch result {
                    case .failure(let error):
                        break
                    case .success(let deal):
                        debugPrint(deal)
                    }
                })
            }.store(in: &store)
    }

//    private func decrypt() {
//        guard let key = deal.encryptedSecretKey, let base64Data = Data(base64Encoded: key) else { return }
//        Crypto.decrypt(
//            encryptedData: base64Data,
//            with: state.account.secretKey)
//        .receive(on: RunLoop.main)
//        .sink { result in
//            after?()
//        } receiveValue: { data in
//            debugPrint(String(data: data, encoding: .utf8))
//        }.store(in: &store)
//    }
}
