//
//  PrepaidView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 26.03.2024.
//

import SwiftUI

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct PrepaidView: View {
    enum Mode {
        case amount, percent
    }

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<PrepaidViewModel.State, PrepaidViewModel.Input>
    @State var mode: Mode
    @State var amountValue: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Picker("", selection: $mode) {
                        Text("Amount").tag(Mode.amount)
                        Text("Percent").tag(Mode.percent)
                    }
                    .frame(width: 200)
                    .pickerStyle(SegmentedPickerStyle())
                    Spacer()
                }
                HStack {
                    Spacer()
                    AmountFieldView(
                        amountValue: $amountValue,
                        color: R.color.textBase.color,
                        currencyCode: mode == .amount ? R.string.localizable.buyTokenCtus() : "%",
                        didChange: { newAmount in
                            viewModel.trigger(.setAmount(newAmount))
                        },
                        didFinish: {
                        }) { value in
                            return value
                        }
                    Spacer()
                }
                Text("≈ 30% of amount deal")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)
                    .padding(.bottom, 8)
                Spacer()

     
                Text("Will be paid to the executor once the deal begins. That funds can't be returned if the deal is canceled.")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                CButton(
                    title: R.string.localizable.commonSave(),
                    style: .primary,
                    size: .large,
                    isLoading: false,
                    isDisabled: false,
                    action: {
                        viewModel.trigger(.save)
                    })
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .toolbar {
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
            .navigationTitle("Prepayment")
            .navigationBarTitleDisplayMode(.inline)
            .baseBackground()
        }
    }
}

#Preview {
    PrepaidView(
        viewModel: .init(PrepaidViewModel(
            state: .init())),
        mode: .amount
    )
}
