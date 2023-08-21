//
//  ReferralViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 16.08.2023.
//

import Foundation
import ContractusAPI

enum ReferralInput {
    case apply(String), create, resetError
}

struct PrizeItem: Hashable {
    let type: ReferralProgram.PrizeType
    let title: String
    let subtitle: String?
    let amount: String
    let applied: Bool
}

struct ReferralState {
    enum ErrorState: Equatable {
        case error(String)
    }
    
    enum State {
        case loading, loaded, applied
    }
    
    var state: State
    var errorState: ErrorState?
    var promocode: String?
    var prizes: [PrizeItem]
}

final class ReferralViewModel: ViewModel {
    
    @Published private(set) var state: ReferralState
    
    private var referralService: ContractusAPI.ReferralService?
    
    init(
        referralService: ContractusAPI.ReferralService? = nil
    ) {
        self.referralService = referralService
        
        self.state = .init(
            state: .loading,
            promocode: nil,
            prizes: []
        )
        
        Task { @MainActor in
            do {
                let referral = try await getReferral()
                var newState = self.state
                newState.promocode = referral?.promocode
                newState.prizes = (referral?.prizes ?? []).map { $0.toPrizeItem() }
                if (referral?.prizes ?? []).contains(where: { $0.type == .applyPromocode && $0.applied}) {
                    newState.state = .applied
                } else {
                    newState.state = .loaded
                }
                self.state = newState
            } catch {
                var newState = self.state
                newState.errorState = .error(error.localizedDescription)
                newState.state = .loaded
                self.state = newState
            }
        }
    }
    
    func trigger(_ input: ReferralInput, after: AfterTrigger?) {
        switch input {
        case .apply(let promo):
            let data = ReferralService.CreatePromocode(promocode: promo)

            Task { @MainActor in
                do {
                    let response = try await applyPromocode(data: data)
                    var newState = self.state
                    if response?.status == .error {
                        EventService.shared.send(event: ExtendedAnalyticsEvent.referralApplyCodeError(R.string.localizable.promocodeNotFound()))
                        newState.errorState = .error(R.string.localizable.promocodeNotFound())
                    } else {
                        newState.state = .applied
                        EventService.shared.send(event: DefaultAnalyticsEvent.referralApplyCodeSuccess)
                    }
                    self.state = newState
                } catch {
                    EventService.shared.send(event: ExtendedAnalyticsEvent.referralApplyCodeError(error.localizedDescription))
                    var newState = self.state
                    newState.errorState = .error(error.localizedDescription)
                    newState.state = .loaded
                    self.state = newState
                }
            }
        case .create:
            Task { @MainActor in
                do {
                    let referral = try await createPromocode()
                    var newState = self.state
                    newState.promocode = referral?.promocode
                    newState.prizes = (referral?.prizes ?? []).map { $0.toPrizeItem() }
                    newState.state = .loaded
                    self.state = newState
                } catch {
                    var newState = self.state
                    newState.errorState = .error(error.localizedDescription)
                    newState.state = .loaded
                    self.state = newState
                }
            }
        case .resetError:
            self.state.errorState = nil
        }
    }
    
    private func getReferral() async throws -> ReferralProgram? {
        return try await withCheckedThrowingContinuation({ continuation in
            referralService?.getInformation { result in
                continuation.resume(with: result)
            }
        })
    }
    
    private func createPromocode() async throws -> ReferralProgram? {
        return try await withCheckedThrowingContinuation({ continuation in
            referralService?.createPromocode { result in
                continuation.resume(with: result)
            }
        })
    }
    
    private func applyPromocode(data: ReferralService.CreatePromocode) async throws -> ReferralProgramResult? {
        return try await withCheckedThrowingContinuation({ continuation in
            referralService?.applyPromocode(data) { result in
                continuation.resume(with: result)
            }
        })
    }
}

extension ReferralProgram.Prize {
    func toPrizeItem() -> PrizeItem {
        return .init(
            type: self.type,
            title: self.name(),
            subtitle: self.count > 1 ? "\(count) \(R.string.localizable.referralPrizeTimes())" : nil,
            amount: self.count > 1 ? self.amount.formatted(withCode: true) : self.price.formatted(withCode: true),
            applied: applied
        )
    }
    
    func name() -> String {
        switch self.type {
        case .signup:
            return R.string.localizable.referralPrizeSignup()
        case .applyPromocode:
            return R.string.localizable.referralPrizeApply()
        case .applyPromocodeReferrer:
            return R.string.localizable.referralPrizeApplyRefferer()
        case .unknown:
            return R.string.localizable.referralPrizeUnknown()
        }
    }
}
