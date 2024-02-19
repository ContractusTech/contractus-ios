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
    case dismissError
}

struct AddContractorState {

    enum ErrorState: Equatable {
        case error(String)
    }

    enum State: Equatable {
        case none, validPublicKey, loading, invalidPublicKey(String), successAdded
    }

    let participateType: ParticipateType
    var deal: Deal
    let shareableData: Shareable
    let account: CommonAccount
    var publicKey: String = ""
    var state: State = .none
    var errorState: ErrorState?
    var blockchain: Blockchain

    var isLoading: Bool {
        switch state {
        case .loading:
            return true
        default:
            return false
        }

    }

    var ownerIsClient: Bool {
        deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey
    }
}

final class AddContractorViewModel: ViewModel {

    @Published private(set) var state: AddContractorState
    private var bag = Set<AnyCancellable>()
    private var dealService: DealsService?

    init(
        account: CommonAccount,
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
            state: blockchain.isValidPublicKey(string: publicKey ?? "") ? .validPublicKey : .none,
            blockchain: blockchain)
    }

    
    func trigger(_ input: AddContractorInput, after: AfterTrigger? = nil) {
        switch input {
        case .dismissError:
            state.errorState = nil
        case .validate(let publicKey):
            self.state.state = state.blockchain.isValidPublicKey(string: publicKey) ? .validPublicKey : .invalidPublicKey(R.string.localizable.addContractorErrorWrongPublicKey(state.blockchain.rawValue))
            checkKeyAlreadyInDeal(publicKey)
            self.state.publicKey = publicKey
        case .addContractor:
            EventService.shared.send(event: ExtendedAnalyticsEvent.dealContractorUpdateTap(state.ownerIsClient ? .executor : .client))
            self.state.state = .loading
            self.addContractor()
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):

                        self.state.errorState = .error(error.localizedDescription)
                        self.state.state = .none
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

    func checkKeyAlreadyInDeal(_ publicKey: String) {
        if publicKey == self.state.deal.checkerPublicKey || publicKey == self.state.deal.ownerPublicKey {
            self.state.state = .invalidPublicKey(R.string.localizable.addContractorErrorContractor())
        }
        if publicKey == self.state.deal.contractorPublicKey || publicKey == self.state.deal.ownerPublicKey {
            self.state.state = .invalidPublicKey(R.string.localizable.addContractorErrorChecker())
        }
    }
}
