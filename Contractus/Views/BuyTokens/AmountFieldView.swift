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
    var currency: String?
    var setValue: (Double) -> Void
    var calculate: (() -> Void)?

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
                .onChange(of: amountValue) { newAmountValue in
                    if let amount = Double(newAmountValue.replacingOccurrences(of: ",", with: ".")) {
                        setValue(amount)
                    } else {
                        setValue(0)
                    }
                    amountPublisher.send(newAmountValue)
                }
                .onReceive(Just(amountValue)) { newValue in
                    var filtered = newValue.filter { "0123456789,.".contains($0) }
                    let components = filtered.replacingOccurrences(of: ",", with: ".").components(separatedBy: ".")
                    if let fraction = components.last, components.count > 1, fraction.count > 5 {
                        filtered = String(filtered.dropLast())
                    }
                    if filtered != newValue {
                        self.amountValue = filtered
                    }
                }
                .onReceive(
                    amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                ) { newAmountValue in
                    calculate?()
                }
                .padding(.leading, 12)

            Text(currency ?? R.string.localizable.buyTokenCtus())
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
        setValue: { _ in
            
        }
    )
}
