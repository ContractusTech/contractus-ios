//
//  ChangeAmountView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import SwiftUI
import ContractusAPI
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
    @State private var token: ContractusAPI.Token
    
    @State var holderMode: Bool = false

    let amountPublisher = PassthroughSubject<String, Never>()
    private let availableTokens: [ContractusAPI.Token]
    private var didChange: (Amount, AmountValueType, Bool) -> Void

    init(
        viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>,
        availableTokens: [ContractusAPI.Token],
        didChange: @escaping (Amount, AmountValueType, Bool) -> Void
    ) {
        self._amountString = State(initialValue: viewModel.state.amount.formatted())
        self._token = State(initialValue: viewModel.state.amount.token)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.availableTokens = availableTokens
        self.didChange = didChange
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Picker("", selection: $token) {
                                ForEach(availableTokens, id: \.self) {
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
                        .background(R.color.textFieldBackground.color)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 0.5)
                                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                        )

                        switch viewModel.amountType {
                        case .deal:
                            VStack(spacing: 12) {
                                if !viewModel.state.checkerIsYou {
                                    HStack {
                                        VStack {
                                            Text(R.string.localizable.changeAmountVerificationAmount())
                                                .font(.body)
                                                .foregroundColor(viewModel.state.amountType == .checker ? R.color.textBase.color : R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }

                                        Spacer()
                                        if viewModel.state.state != .loading  {
                                            Text(viewModel.state.checkerAmount.formatted(withCode: true))
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(viewModel.state.amountType == .checker ? R.color.textBase.color : R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(R.color.thirdBackground.color)
                                                .frame(width: 42, height: 19)
                                        }
                                    }
                                }
                            }
                            VStack(spacing: 16) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(R.string.localizable.changeAmountHolderMode())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(R.string.localizable.changeAmountHolderModeHint())
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                    
                                    Toggle(isOn: $holderMode) {}
                                        .disabled(viewModel.state.tier == .basic)
                                }
                                
                                BorderDivider(
                                    color: R.color.textFieldBorder.color,
                                    width: 1
                                )
                                .padding(.horizontal, -12)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(R.string.localizable.changeAmountFeeTitle())
                                                .font(.body)
                                                .foregroundColor(R.color.textBase.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        if viewModel.state.feePercent == 0 && viewModel.state.state != .loading {
                                            if viewModel.state.noAmount {
                                                Text("➖")
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                                            }
                                        } else {
                                            if !viewModel.state.feeFormatted.isEmpty  {
                                                Text(viewModel.state.feeFormatted)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(R.color.textBase.color)
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(R.color.thirdBackground.color)
                                                    .frame(width: 42, height: 19)
                                            }
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 4) {

                                        if !viewModel.state.fiatFeeFormatted.isEmpty {
                                            Text("\(R.string.localizable.changeAmountEstimateFiat()) \(viewModel.state.fiatFeeFormatted)")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }

                                        Text(R.string.localizable.changeAmountFeeCalculateDescription())
                                            .font(.footnote)
                                            .foregroundColor(R.color.labelTextAttention.color)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            .padding(.all, 12)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                            )

                            HStack {
                                VStack {
                                    Text(R.string.localizable.changeAmountTotalAmount())
                                        .font(.body)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                                if viewModel.state.state != .loading  {
                                    Text(viewModel.state.totalAmount.formatted(withCode: true))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(R.color.thirdBackground.color)
                                        .frame(width: 42, height: 19)
                                }
                            }
                        case .checker:
                            VStack(spacing: 16) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(R.string.localizable.changeAmountDealAmount())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                    
                                    Text(viewModel.state.dealAmount.formatted(withCode: true))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                BorderDivider(
                                    color: R.color.textFieldBorder.color,
                                    width: 1
                                )
                                .padding(.horizontal, -12)
                                
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(R.string.localizable.changeAmountHolderMode())
                                            .font(.body)
                                            .foregroundColor(R.color.textBase.color)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                    
                                    if holderMode {
                                        Label(text: R.string.localizable.commonOn(), type: .primary)
                                    } else {
                                        Label(text: R.string.localizable.commonOff(), type: .default)
                                    }
                                }
                                
                                BorderDivider(
                                    color: R.color.textFieldBorder.color,
                                    width: 1
                                )
                                .padding(.horizontal, -12)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(R.string.localizable.changeAmountFeeTitle())
                                                .font(.body)
                                                .foregroundColor(R.color.textBase.color)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        if viewModel.state.feePercent == 0 && viewModel.state.state != .loading {
                                            if viewModel.state.noAmount {
                                                Text("➖")
                                                    .font(.body)
                                                    .foregroundColor(R.color.secondaryText.color)
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                Label(text: R.string.localizable.changeAmountFeeFree(), type: .primary)
                                            }
                                        } else {
                                            if !viewModel.state.feeFormatted.isEmpty  {
                                                Text(viewModel.state.feeFormatted)
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(R.color.textBase.color)
                                                    .multilineTextAlignment(.leading)
                                            } else {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(R.color.thirdBackground.color)
                                                    .frame(width: 42, height: 19)
                                            }
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        if !viewModel.state.fiatFeeFormatted.isEmpty {
                                            Text("\(R.string.localizable.changeAmountEstimateFiat()) \(viewModel.state.fiatFeeFormatted)")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundColor(R.color.secondaryText.color)
                                                .multilineTextAlignment(.leading)
                                        }

                                        Text(R.string.localizable.changeAmountFeeCalculateDescription())
                                            .font(.footnote)
                                            .foregroundColor(R.color.labelTextAttention.color)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(R.color.textFieldBorder.color, lineWidth: 1)
                            )

                            HStack {
                                VStack {
                                    Text(R.string.localizable.changeAmountTotalAmount())
                                        .font(.body)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                                if viewModel.state.state != .loading  {
                                    Text(viewModel.state.totalAmount.formatted(withCode: true))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(R.color.thirdBackground.color)
                                        .frame(width: 42, height: 19)
                                }
                            }
                        case .ownerBond, .contractorBond:
                            Text(bondText)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                VStack(spacing: 24) {
                    Text(R.string.localizable.changeAmountFeeDescription())
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.leading)

                    CButton(
                        title: R.string.localizable.commonChange(),
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.state.state == .changingAmount,
                        isDisabled: (!viewModel.state.isValid || viewModel.state.state == .loading)
                    ) {
                        viewModel.trigger(.update)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
            }
            .onChange(of: amountString, perform: { newAmount in
                amountPublisher.send(newAmount)
            })
            .onChange(of: viewModel.state.state, perform: { newValue in
                if newValue == .success {
                    didChange(viewModel.amount, viewModel.state.amountType, viewModel.allowHolderMode)
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .onChange(of: token, perform: { newToken in
                viewModel.trigger(.changeToken(newToken))
            })
            .onReceive(amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main), perform: { amountText in
                viewModel.trigger(.changeAmount(amountText, token))
            })
            .onChange(of: holderMode, perform: { newValue in
                viewModel.trigger(.changeholderMode(newValue))
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            if let allowHolderMode = viewModel.state.deal.allowHolderMode {
                self.holderMode = allowHolderMode
                viewModel.trigger(.changeholderMode(allowHolderMode))
            }
            viewModel.trigger(.changeAmount(amountString, token))
        }
    }

    var title: String {
        switch viewModel.state.amountType {
        case .deal:
            return R.string.localizable.changeAmountTitle()
        case .checker:
            return "Cost of verification"
        case .contractorBond:
            if viewModel.contractorIsClient {
                if viewModel.state.clientIsYou {
                    return "Bond of client (you)"
                }
                return "Bond of client"
            } else {
                if !viewModel.state.clientIsYou {
                    return "Bond of executor (you)"
                }
                return "Bond of executor"
            }
        case .ownerBond:
            if viewModel.ownerIsClient {
                if viewModel.state.clientIsYou {
                    return "Bond of client (you)"
                }
                return "Bond of client"
            } else {
                if !viewModel.state.clientIsYou {
                    return "Bond of executor (you)"
                }
                return "Bond of executor"
            }
        }
    }
    
    var bondText: String {
        switch viewModel.state.amountType {
        case .deal:
            return ""
        case .checker:
            return ""
        case .contractorBond:
            if viewModel.contractorIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            }
        case .ownerBond:
            if viewModel.ownerIsClient {
                if viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            } else {
                if !viewModel.state.clientIsYou {
                    return R.string.localizable.changeAmountBondOwner()
                }
                return R.string.localizable.changeAmountBondContractor()
            }
        }
    }
}

struct ChangeAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAmountView(
            viewModel: AnyViewModel<ChangeAmountState, ChangeAmountInput>(ChangeAmountViewModel(
                deal: Mock.deal, account: Mock.account, amountType: .checker, dealService: nil, tier: .basic)), availableTokens: Mock.tokenList) { _, _, _  in

                }
    }
}

