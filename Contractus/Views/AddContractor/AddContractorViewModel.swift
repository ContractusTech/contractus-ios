//
//  AddContractorViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.09.2022.
//

import Foundation
import Combine
import ContractusAPI
import SolanaSwift

enum AddContractorInput {
    case validate(String)
    case addContractor
}

struct AddContractorState {
    
    enum State: Equatable {
        case none, validPublicKey, loading, invalidPublicKey, successAdded, error(String)
    }

    let participateType: ParticipateType
    var deal: Deal
    let shareableData: Shareable
    let account: SolanaSwift.Account
    var publicKey: String = ""
    var state: State = .none
    var blockchain: Blockchain

    var isLoading: Bool {
        switch state {
        case .loading:
            return true
        default:
            return false
        }

    }

    var accountIsClient: Bool {
        deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey.base58EncodedString
    }
}

final class AddContractorViewModel: ViewModel {

    @Published private(set) var state: AddContractorState
    private var bag = Set<AnyCancellable>()
    private var dealService: DealsService?

    init(
        account: SolanaSwift.Account,
        participateType: ParticipateType,
        deal: Deal,
        sharedSecretBase64: String,
        blockchain: Blockchain,
        dealService: DealsService?,
        publicKey: String? = nil)
    {
        self.dealService = dealService
        self.state = .init(
            participateType: participateType,
            deal: deal,
            shareableData: ShareableDeal(dealId: deal.id, secretBase64: sharedSecretBase64),
            account: account,
            publicKey: publicKey ?? "",
            state: AccountValidator.isValidPublicKey(string: publicKey ?? "", blockchain: blockchain) ? .validPublicKey : .none,
            blockchain: blockchain)
    }

    
    func trigger(_ input: AddContractorInput, after: AfterTrigger? = nil) {
        switch input {
        case .validate(let publicKey):
            self.state.state = AccountValidator.isValidPublicKey(string: publicKey, blockchain: state.blockchain) ? .validPublicKey : .invalidPublicKey
            self.state.publicKey = publicKey
        case .addContractor:
            self.state.state = .loading
            self.addContractor()
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        debugPrint(error)
                        self.state.state = .error(error.localizedDescription)
                    case .finished:
                        break
                    }
                } receiveValue: { deal in
                    self.state.deal = deal
                    self.state.state = .successAdded
                }
                .store(in: &bag)

        }
    }

    func addContractor() -> Future<Deal, Error> {
        Future { promise in
            self.dealService?.addParticipate(
                to: self.state.deal.id,
                data: NewParticipate(
                    type: self.state.participateType,
                    publicKey: self.state.publicKey,
                    blockchain: self.state.blockchain),
                completion: { result in
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
