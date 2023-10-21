//
//  BuyTokensViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

import ContractusAPI
import Foundation
import Alamofire

enum BuyTokensInput {
    case resetError, setValue(Double), calculate, create
}

struct BuyTokensState {
    enum ErrorState: Equatable {
        case error(String)
    }
    
    enum State: Equatable {
        case loading, loaded, openURL(String), openPayment(PaymentRequest)
    }

    struct PaymentRequest: Equatable {
        let paymentUrl: URL
        let method: String

        let successUrl: URL?
        let failUrl: URL?
        let params: [String: String]
    }

    var account: CommonAccount
    var state: State
    var errorState: ErrorState?
    var value: Double = 10000.00
    var calculate: CalculateResult?

    var requestType: CheckoutService.CreateUrlRequest.CheckoutType

    var price: String {
        if let calculate = calculate {
            return "\(calculate.fiatCurrency) \(calculate.tokenPrice.formatted())"
        } else {
            return ""
        }
    }

    var pay: String {
        if let calculate = calculate {
            return " - \(calculate.fiatCurrency) \(calculate.tokenAmount.formatted())"
        } else {
            return ""
        }
    }

    var canNotBuy: Bool {
        value == 0
    }
}

final class BuyTokensViewModel: ViewModel {

    @Published private(set) var state: BuyTokensState

    private var checkoutService: ContractusAPI.CheckoutService?

    init(
        account: CommonAccount,
        checkoutService: ContractusAPI.CheckoutService? = nil
    ) {
        self.checkoutService = checkoutService
        self.state = .init(
            account: account,
            state: .loading,
            requestType: .advcash
        )
        
        self.trigger(.calculate) {}
    }
    
    func trigger(_ input: BuyTokensInput, after: AfterTrigger?) {
        switch input {
        case .resetError:
            self.state.errorState = nil
        case .setValue(let value):
            self.state.value = value
        case .calculate:
            let data = CheckoutService.CalculateRequest(amount: state.value)
            self.state.state = .loading
            Task { @MainActor in
                do {
                    let response = try await calculate(data: data)
                    var newState = self.state
                    newState.calculate = response
                    newState.state = .loaded
                    self.state = newState
                } catch {
                    self.state.state = .loaded
                    self.state.errorState = .error(error.localizedDescription)
                }
            }
        case .create:
            self.state.state = .loading
            let data = CheckoutService.CreateUrlRequest(
                type: .advcash,
                amount: state.value,
                blockchain: "solana",
                publicKey: state.account.publicKey
            )
            Task { @MainActor in
                do {
                    let response = try await create(data: data)
                    switch state.requestType {
                    case .nowpayments:
                        self.state.state = .openURL(response.paymentUrl)
                    case .advcash:
                        if let paymentData = try? BuyTokensState.PaymentRequest(by: response) {
                            self.state.state = .openPayment(paymentData)
                        } else {
                            self.state.state = .loaded
                            self.state.errorState = .error(R.string.localizable.commonError())
                        }
                    }

                } catch {
                    self.state.state = .loaded
                    self.state.errorState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func calculate(data: CheckoutService.CalculateRequest) async throws -> CalculateResult {
        try await withCheckedThrowingContinuation { continuation in
            checkoutService?.calculate(data) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func create(data: CheckoutService.CreateUrlRequest) async throws -> CreateUrlResult {
        try await withCheckedThrowingContinuation { continuation in
            checkoutService?.create(data) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension BuyTokensState.PaymentRequest {

    enum PaymentRequestError: Error {
        case paymentUrlNotFound
    }

    init(by result: CreateUrlResult) throws {
        guard let url =  URL(string: result.paymentUrl) else {
            throw PaymentRequestError.paymentUrlNotFound
        }
        self.paymentUrl = url
        self.successUrl = URL(string: result.successUrl ?? "")
        self.failUrl = URL(string: result.failUrl ?? "")
        self.params = result.params ?? [:]
        self.method = result.method ?? "POST"
    }

    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: self.paymentUrl)
        request.httpMethod = self.method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = try? URLEncodedFormEncoder().encode(self.params).data(using: .utf8)
        return request
    }
}
