//
//  CreateDealViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.09.2022.
//

import Foundation
import ContractusAPI
import Combine
import SolanaSwift
import UIKit

enum CreateDealInput {
    case createDealAsClient,
         createDealAsExecutor,
         copy
}

struct CreateDealState {

    enum State {
        case none, creating, success, error
    }
    var account: CommonAccount
    var state: State = .none
    var createdDeal: Deal?
    var errorMessage: String = ""
    var shareable: Shareable?
}

final class CreateDealViewModel: ViewModel {

    @Published private(set) var state: CreateDealState

    private var dealsAPIService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(
        account: CommonAccount,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?)
    {
        self.state = CreateDealState(account: account)
        self.dealsAPIService = dealsAPIService
    }

    func trigger(_ input: CreateDealInput, after: AfterTrigger? = nil) {
        switch input {
        case .createDealAsClient:
            create(for: .client)
        case .createDealAsExecutor:
            create(for: .executor)
        case .copy:
            if let share = state.shareable?.shareContent {
                UIPasteboard.general.string = share
            }
        }
    }

    // MARK: - Private Methods

    private func create(for role: OwnerRole) {
        let key = String.random(length: AppConfig.sharedKeyLength)
        guard let sharedParts = try? SSS.createShares(data: [UInt8](key.utf8)),
              let secretServerKey = sharedParts.first?.toBase64(),
              let secretPartnerKey = sharedParts.last?.toBase64() else {
            return
        }

        self.state.state = .creating
        self.state.errorMessage = ""

        Crypto.encrypt(message: key, with: state.account.privateKey)
            .flatMap({ encryptedSecretKey in
                Future<NewDeal, Never> { promise in
                    let newDeal = NewDeal(
                        role: role,
                        encryptedSecretKey: encryptedSecretKey.base64EncodedString(),
                        secretKeyHash: Crypto.sha3(data: encryptedSecretKey),
                        sharedKey: secretServerKey)
                    promise(.success(newDeal))
                }
            })
            .flatMap({ deal in
                self.createDeal(deal: deal)
            })
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    self.state.state = .error
                    self.state.errorMessage = error.localizedDescription
                case .finished:
                    break
                }

            } receiveValue: { deal in
                self.state.shareable = ShareableDeal(dealId: deal.id, secretBase64: secretPartnerKey)
                self.state.state = .success
                self.state.createdDeal = deal
            }
            .store(in: &store)
    }

    private func createDeal(deal: NewDeal) -> Future<Deal, Error> {
        Future { promise in
            self.dealsAPIService?.create(
                data: deal, completion: { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error as Error))
                case .success(let deal):
                    promise(.success(deal))
                }
            })
        }
    }
}
