//
//  SelectAmountView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.10.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let arrows = Image(systemName: "arrow.left.arrow.right.circle.fill")
    static let backImage = Image(systemName: "chevron.left")
}

struct SelectAmountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>

    @State var amountValue: String = ""

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
                HStack {
                    Spacer()
                    AmountFieldView(
                        amountValue: $amountValue,
                        color: R.color.textBase.color,
                        currencyCode: viewModel.state.reversed ? viewModel.state.currency.code : viewModel.state.selectedToken?.code ?? R.string.localizable.buyTokenCtus(),
                        didChange: { newAmount in
                            viewModel.trigger(.setAmount(newAmount))
                        },
                        didFinish: {
                        }) { value in
                            return value.filterAmount(decimals: viewModel.state.selectedToken?.decimals ?? 5)
                        }
                    Spacer()
                }

                Button(action: {
                    viewModel.trigger(.swap)
                    amountValue = viewModel.state.amount
                }, label: {
                    Constants.arrows
                        .imageScale(.large)
                        .rotationEffect(.degrees(90))
                })
                .padding(.top, 25)
                .padding(.trailing, 10)
            }
            VStack {
                HStack {
                    if !viewModel.state.convertedFormatted.isEmpty {

                        Text("≈ \(viewModel.state.convertedFormatted)")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)
                            .padding(.bottom, 8)

                    }
                }
                .frame(height: 24)

                if let maxAmount = viewModel.state.tokenInfo?.amount.valueFormattedWithCode {
                    HStack {
                        Text(R.string.localizable.sendTokensBalanceTitle())
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.textBase.color)
                        Spacer()
                        Text(maxAmount)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)

                        Button(action: {
                            viewModel.trigger(.setMaxAmount)
                            amountValue = viewModel.state.amount
                        }, label: {
                            Text(R.string.localizable.sendTokensMaxTitle())
                                .font(.footnote.weight(.medium))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(R.color.buttonBorderSecondary.color)
                                .cornerRadius(14)
                        })

                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 6)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 1)
                        .fill(R.color.baseSeparator.color)
                    )
                    .padding(.bottom, 24)
                    .padding(.horizontal, 42)
                }
            }
            Spacer()

            HStack {
                Text(R.string.localizable.sendTokensRecipient())
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.textBase.color)
                Spacer()
                Text(ContentMask.mask(from: viewModel.state.recipient))
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Rectangle()
                .foregroundColor(.clear)
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
            )
            .padding(.bottom, 24)
            .padding(.horizontal, 42)
            CButton(
                title: R.string.localizable.commonNext(),
                style: .primary,
                size: .large,
                isLoading: viewModel.state.state == .loading,
                action: {
                    viewModel.trigger(.send)
                })
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .baseBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading: Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Constants.backImage
                    .resizable()
                    .frame(width: 12, height: 21)
                    .foregroundColor(R.color.textBase.color)
            }
        )
        .onAppear {
            amountValue = viewModel.state.amount
        }
    }

    var title: String {
        return R.string.localizable.sendTokensSendTitle(viewModel.state.selectedToken?.code ?? "")
    }
}

#Preview {
    SelectAmountView()
}
