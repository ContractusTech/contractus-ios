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
import Combine

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

    let amountPublisher = PassthroughSubject<String, Never>()
    private let availableCurrencies: [ContractusAPI.Currency]
    private var didChange: (Amount) -> Void

    init(
        viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>,
        defaultCurrency: Currency = .usdc,
        availableCurrencies: [ContractusAPI.Currency] = Currency.availableCurrencies,
        didChange: @escaping (Amount) -> Void) {

            self._amountString = State(initialValue: viewModel.state.amount.formatted())
            self._currency = State(initialValue: viewModel.state.amount.currency)
            self._viewModel = StateObject(wrappedValue: viewModel)
            self.availableCurrencies = availableCurrencies
            self.didChange = didChange

        }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Picker("", selection: $currency) {
                                ForEach(availableCurrencies, id: \.self) {
                                    Text($0.code)
                                        .font(.body.weight(.semibold))
                                }
                            }
                            .pickerStyle(.menu)
                            Divider().frame(height: 30)
                            TextField(R.string.localizable.changeAmountAmount(), text: $amountString)
                                .introspectTextField { tf in
                                    tf.becomeFirstResponder()
                                }
                                .textFieldStyle(LargeTextFieldStyle())
                        }
                        .background(R.color.thirdBackground.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                        )
                        Divider()

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(R.string.localizable.changeAmountFeeTitle())
                                    .font(.body)
                                    .foregroundColor(R.color.textBase.color)
                                    .multilineTextAlignment(.leading)
                                Text(R.string.localizable.changeAmountFeeDescription())
                                    .font(.footnote)
                                    .foregroundColor(R.color.secondaryText.color)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()
                            if viewModel.state.fee == 0 && viewModel.state.state != .loading {
                                Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                            } else {
                                if !viewModel.state.feeFormatted.isEmpty  {
                                    Text("\(viewModel.state.feeFormatted) %")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                } else {
                                    RoundedRectangle(cornerRadius: 16).fill(R.color.thirdBackground.color)
                                        .frame(width: 42, height: 24)
                                }
                            }
                        }
                        Divider()


                        HStack {
                            Text(R.string.localizable.changeAmountTotalAmount())
                                .font(.body)
                                .foregroundColor(R.color.textBase.color)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if viewModel.state.state != .loading  {
                                Text(viewModel.state.totalAmount.formatted(withCode: true))
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(R.color.textBase.color)
                                    .multilineTextAlignment(.leading)
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(R.color.thirdBackground.color)
                                    .frame(width: 42, height: 24)
                            }
                        }


                    }
                }


                CButton(
                    title: R.string.localizable.commonChange(),
                    style: .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .changingAmount,
                    isDisabled: (!viewModel.state.isValid || viewModel.state.state == .loading))
                {
                    viewModel.trigger(.update)
                }

                .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
            }
            .onChange(of: amountString, perform: { newAmount in
                amountPublisher.send(newAmount)
            })
            .onChange(of: viewModel.state.state, perform: { newValue in
                if newValue == .success {
                    didChange(viewModel.amount)
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .onReceive(amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main), perform: { amountText in
                viewModel.trigger(.changeAmount(amountText, currency))
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
        .onAppear {
            viewModel.trigger(.changeAmount(amountString, currency))
        }
    }
}

struct ChangeAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAmountView(
            viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(ChangeAmountViewModel(
                dealId: "", amount: Amount("10000", currency: .usdc), feeAmount: Amount("10000", currency: .usdc), dealService: nil))) { amount in

                }
    }
}

