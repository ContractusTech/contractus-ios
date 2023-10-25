//
//  AmountFieldView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.10.2023.
//

import SwiftUI
import Combine

struct AmountFieldView: View {
    @Binding var amountValue: String
    var color: Color
    var currencyCode: String
    var maxDigits: Int = 5
    var didChange: (String) -> Void
    var didFinish: (() -> Void)?
    var filter: ((String) -> String)? = nil

    @State private var amountPublisher = PassthroughSubject<String, Never>()
    @FocusState var amountFocused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            TextField("", text: $amountValue)
                .textFieldStyle(.plain)
                .font(.largeTitle.weight(.medium))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .fixedSize(horizontal: amountValue.count < 12, vertical: false)
                .onChange(of: amountValue) { newAmount in
                    didChange(newAmount)
                    amountPublisher.send(newAmount)
                }
                .onReceive(Just(amountValue)) { newValue in
                    let filteredValue = filter?(newValue) ?? newValue
                    if filteredValue != newValue {
                        self.amountValue = filteredValue
                    }
                }
                .onReceive(
                    amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                ) { newAmountValue in
                    didFinish?()
                }
                .padding(.leading, 12)

            Text(currencyCode)
                .font(.largeTitle.weight(.medium))
                .foregroundColor(R.color.secondaryText.color)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 6)
                .padding(.trailing, 12)
                .fixedSize(horizontal: true, vertical: false)
        }
        .overlay(alignment: .bottom) {
            BorderDivider(
                color: R.color.baseSeparator.color,
                width: 2
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 45)
        .padding(.bottom, 16)
        .onAppear {
            amountFocused = true
        }
    }
}

#Preview {
    AmountFieldView(
        amountValue: .constant("10000"),
        color: .black,
        currencyCode: "CTUS",
        didChange: { _ in
            
        }
    )
}
