//
//  ChangeAmountView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import SwiftUI
import struct ContractusAPI.Currency
import struct ContractusAPI.Amount
import Introspect

extension Currency: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct ChangeAmountView: View {

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>
    @State private var amountString: String = ""
    @State private var currency: Currency
    @State private var amountWithFee: Bool = false

    private let availableCurrencies: [ContractusAPI.Currency]
    private var didChange: (Amount) -> Void

    var amountFormatted: Binding<String> {
            Binding<String>(
                get: { amountString },
                set: {
                    viewModel.trigger(.changeAmount($0, currency))
                    amountString = $0
                }
            )
    }

    init(
        viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>,
        defaultCurrency: Currency = .usdc,
        availableCurrencies: [ContractusAPI.Currency] = Currency.availableCurrencies,
        didChange: @escaping (Amount) -> Void) {

            if let amount = viewModel.state.amount {
                self._amountString = State(initialValue: amount.formatted())
                self._currency = State(initialValue: amount.currency)
            } else {
                self._currency = State(initialValue: defaultCurrency)
            }

            self._viewModel = StateObject(wrappedValue: viewModel)
            self.availableCurrencies = availableCurrencies
            self.didChange = didChange
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    HStack {
                        Picker("Select currency", selection: $currency) {
                            ForEach(availableCurrencies, id: \.self) {
                                Text($0.code)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .pickerStyle(.menu)
                        Divider().frame(height: 30)
                        TextField(R.string.localizable.changeAmountAmount(), text: amountFormatted)
                            .introspectTextField { tf in
                                tf.becomeFirstResponder()
                            }
                    }

                    .padding(10)
                    .background(R.color.baseSeparator.color)
                    .cornerRadius(12)
                    Divider()
                    HStack {

                        Toggle(isOn: $amountWithFee) {
                            Text("Include fee to amount")
                            Text("Fee 1.5% from amount contract")
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                                .multilineTextAlignment(.leading)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: R.color.textBase.color))
                    }
                    Divider()

                }
                Spacer()

                CButton(
                    title: R.string.localizable.commonChange(),
                    style: .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .loading,
                    isDisabled: !viewModel.state.isValid)
                {
                    viewModel.trigger(.update)
                }

                .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))

            }
            .onChange(of: viewModel.state.state, perform: { newValue in
                if newValue == .success {
                    if let amount = viewModel.amount {
                        didChange(amount)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }
                }
            }
            .padding()
            .navigationTitle(R.string.localizable.changeAmountTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor()
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct ChangeAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAmountView(
            viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(ChangeAmountViewModel(
                state: .init(dealId: "", amount: Amount("10000", currency: .usdc)),
                dealService: nil))) { amount in

        }

    }
}
