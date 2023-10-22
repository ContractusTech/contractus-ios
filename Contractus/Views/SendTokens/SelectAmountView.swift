//
//  SelectAmountView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 19.10.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let arrows = Image(systemName: "arrow.left.arrow.right.circle.fill")
    static let backImage = Image(systemName: "chevron.left")
}

struct SelectAmountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>

    var stepsState: StepsState

    @State var amountValue: String = ""
    @State var cost: String = ""
    @State var reversed: Bool = false

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .center)) {
                HStack {
                    Spacer()
                    AmountFieldView(
                        amountValue: $amountValue,
                        color: R.color.textBase.color,
                        currency: reversed ? viewModel.state.currency : viewModel.state.stepsState.selectedToken?.code,
                        setValue: { newValue in
                            cost = reversed ? viewModel.state.getCostReversed(amount: newValue) : viewModel.state.getCost(amount: newValue)
                        },
                        calculate: {
                        }
                    )
                    Spacer()
                }

                Button(action: {
                    reversed.toggle()
                    amountValue = cost.decimal
                }, label: {
                    Constants.arrows
                        .imageScale(.large)
                        .rotationEffect(.degrees(90))
                })
                .padding(.top, 25)
                .padding(.trailing, 10)
            }
            
            Text(cost)
                .font(.footnote.weight(.medium))
                .foregroundColor(R.color.secondaryText.color)
                .padding(.bottom, 8)

            Spacer()
            HStack {
                Text(R.string.localizable.sendTokensRecipient())
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.textBase.color)
                Spacer()
                Text(ContentMask.mask(from: stepsState.recipient))
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
            .padding(.horizontal, 58)
            CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, action: {
                viewModel.trigger(.setState({
                    var newStepsState = viewModel.state.stepsState
                    newStepsState.amount = amountValue
                    return newStepsState
                }()))
            })
        }
        .onAppear {
            amountValue = stepsState.amount
            viewModel.trigger(.getBalance)
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
    }

    var title: String {
        return R.string.localizable.sendTokensSendTitle(stepsState.selectedToken?.code ?? "")
    }
}

#Preview {
    SelectAmountView(stepsState: StepsState())
}
