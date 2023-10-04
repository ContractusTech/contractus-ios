//
//  BuyTokensView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct BuyTokensView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: AnyViewModel<BuyTokensState, BuyTokensInput>
    @State var value: String = ""

    init() {
        self._viewModel = .init(
            wrappedValue: .init(BuyTokensViewModel())
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("SOL", text: $value)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.largeTitle.weight(.medium))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding(.top, 45)
                    .padding(.bottom, 6)
                    .onChange(of: value) { newValue in
//                        viewModel.trigger(.resetError)
                    }

                Divider()
                    .foregroundColor(R.color.baseSeparator.color)
                    .padding(.horizontal, 96)
                    .padding(.bottom, 16)

                Text("≈ 100 000 CTUS")
                    .font(.body.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)

                VStack(spacing: 0) {
                    HStack {
                        Text("1 SOL")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text("≈ 20.43 $")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    Divider()
                        .foregroundColor(R.color.baseSeparator.color)

                    HStack {
                        Text("1 CTUS")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text(" ≈ 0.04 $")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    Divider()
                        .foregroundColor(R.color.baseSeparator.color)

                    HStack {
                        Text("Fee")
                            .font(.footnote.weight(.medium))
                        Spacer()
                        Text(" 0.001 SOL")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
                .background(Color.white)
                .cornerRadius(20)
                .padding(.top, 40)
                .padding(.horizontal, 56)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                
                Spacer()

                CButton(title: "Buy", style: .primary, size: .large, isLoading: false, isDisabled: value.isEmpty) {
                    EventService.shared.send(event: DefaultAnalyticsEvent.referralApplyCodeTap)
//                    viewModel.trigger(.apply(value)) {}
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 18)
            .baseBackground()
            .navigationTitle("Buy CTUS")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }
}

struct BuyTokensView_Previews: PreviewProvider {
    static var previews: some View {
        BuyTokensView()
    }
}
