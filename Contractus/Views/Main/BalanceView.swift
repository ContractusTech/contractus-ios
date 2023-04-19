//
//  BalanceView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.09.2022.
//

import SwiftUI
import ContractusAPI
import BigInt

fileprivate enum Constants {
    static let noneCoinImage = Image("NONE-CoinLogo")
    static let swapImage = Image(systemName: "arrow.triangle.swap")
}

struct BalanceViewModel {

    struct WrapTokens {
        let tokens: [Amount]
    }
    let estimateAmountFormatted: String
    let wrap: WrapTokens
    let tokens: [Amount]
    var canWrap: Bool {
        wrap.tokens.count == 2
    }

    init(balance: Balance, currency: Currency = .usd) {
        estimateAmountFormatted = currency.format(double: balance.estimateAmount, withCode: true) ?? ""
        var tokens: [Amount] = []
        var wrap: [Amount] = []
        balance.tokens.forEach { item in
            if balance.wrap.contains(item.token.code) {
                wrap.append(item)
            } else {
                tokens.append(item)
            }
        }

        self.wrap = .init(tokens: wrap)
        self.tokens = tokens
    }
}

struct BalanceView: View {

    enum BalanceState {
        case empty
        case loaded(BalanceViewModel)
    }

    struct Coin: Identifiable, Equatable {
        static func == (lhs: BalanceView.Coin, rhs: BalanceView.Coin) -> Bool {
            lhs.id == rhs.id
        }

        var id: String {
            self.amount.token.code
        }
        let amount: Amount
        var logo: Image {
            guard let image = UIImage(named: "\(self.amount.token.code)-CoinLogo") else {
                return Constants.noneCoinImage
            }
            return Image(uiImage: image)
        }
    }

    var state: BalanceState = .empty
    var topUpAction: () -> Void
    var swapAction: (Amount, Amount) -> Void

    var body: some View {
        VStack {
            // MARK: - Top
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch state {
                    case .empty:
                        Rectangle()
                            .fill(R.color.thirdBackground.color.opacity(0.4))
                            .cornerRadius(4)
                            .frame(width: 100, height: 15, alignment: .leading)
                            .padding(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        Rectangle()
                            .fill(R.color.thirdBackground.color.opacity(0.4))
                            .cornerRadius(8)
                            .frame(width: 140, height: 32, alignment: .leading)

                        Rectangle()
                            .cornerRadius(8)
                            .frame(width: 0, height: 10, alignment: .leading)

                    case .loaded(let balance):
                        Text(R.string.localizable.balanceEstimate())
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.secondaryText.color)
                        Text(balance.estimateAmountFormatted)
                            .font(.largeTitle.weight(SwiftUI.Font.Weight.light))
                            .foregroundColor(R.color.textBase.color)
                    }

                }
                .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                Spacer()

                Button {
                    topUpAction()
                } label: {
                    R.image.plus.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                        .foregroundColor(R.color.textBase.color)


                }
                .frame(width: 46, height: 46, alignment: .center)
                .buttonStyle(RoundedSecondaryMediumButton())
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 8))

            // MARK: - Coins
            switch state {
            case .empty:

                VStack {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 12){
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 124, height: 16, alignment: .leading)
                            Spacer()
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 80, height: 16, alignment: .leading)
                        }
                        .padding(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
                        Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                        HStack(alignment: .center, spacing: 12){
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 124, height: 16, alignment: .leading)
                            Spacer()
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 80, height: 16, alignment: .leading)
                        }
                        .padding(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
                    }
                    .padding(8)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(16)

                }
            case .loaded(let balance):
                VStack(spacing: 4) {
                    if !balance.wrap.tokens.isEmpty {
                        ZStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                ForEach(balance.wrap.tokens) { token in
                                    HStack(alignment: .center, spacing: 12) {
                                        Text(token.token.code)
                                            .font(.footnote.weight(.semibold))
                                            .textCase(.uppercase)
                                            .foregroundColor(R.color.textBase.color)
                                        Spacer()
                                        Text(token.formatted())
                                            .font(.footnote.weight(.semibold))
                                            .textCase(.uppercase)
                                            .foregroundColor(R.color.textBase.color)
                                    }
                                    .padding(.top, 6)
                                    .padding(.bottom, 6)
                                    if token.token.code != balance.wrap.tokens.last?.token.code { Divider().foregroundColor(R.color.buttonBorderSecondary.color) }
                                }
                            }
                            .padding(12)
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(16)
                            if balance.canWrap {
                                Button {
                                    swapAction(balance.wrap.tokens.first!, balance.wrap.tokens.last!)
                                } label: {
                                    HStack {
                                        Constants.swapImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 15, height: 15)
                                            .foregroundColor(R.color.textBase.color)
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 15)
                                            .fill(R.color.secondaryBackground.color)

                                        )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(R.color.buttonBorderSecondary.color, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    if !balance.tokens.isEmpty {
                        VStack(alignment: .leading) {
                            ForEach(balance.tokens) { token in
                                HStack(alignment: .center, spacing: 12){
                                    Text(token.token.code)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(R.color.textBase.color)
                                    Spacer()
                                    Text(token.formatted())
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(R.color.textBase.color)
                                }
                                .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12))
                                if token.token.code != balance.tokens.last?.token.code { Divider().foregroundColor(R.color.buttonBorderSecondary.color) }
                            }
                        }
                        .background(R.color.secondaryBackground.color)
                        .cornerRadius(16)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

                    } else {
                        EmptyView()
                    }
                }
            }

        }
    }
}

struct BalanceView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            BalanceView(state: .loaded(.init(balance: .init(estimateAmount: 14.0, tokens: [.init(BigUInt(0), token: .from(code: "SOL")), .init(BigUInt(0), token: .from(code: "WSOL")), .init(BigUInt(0), token: .from(code: "USDC"))], blockchain: "solana", wrap: ["SOL", "WSOL"])))) {

            } swapAction: { _, _ in

            }

            BalanceView(state: .empty) {

            } swapAction: { _, _ in

            }
        }
        .baseBackground()
        .preferredColorScheme(.light)

        VStack {
            BalanceView(state: .loaded(.init(balance: .init(estimateAmount: 14.0, tokens: [.init(BigUInt(0), token: .from(code: "SOL")), .init(BigUInt(0), token: .from(code: "WSOL")), .init(BigUInt(0), token: .from(code: "USDC"))], blockchain: "solana", wrap: ["SOL", "WSOL"])))) {

            } swapAction: { _, _ in

            }

            BalanceView(state: .empty) {

            } swapAction: { _, _ in

            }
        }
        .baseBackground()
        .preferredColorScheme(.dark)


    }
}


extension Amount: Identifiable {
    public var id: String {
        self.token.code
    }
}
