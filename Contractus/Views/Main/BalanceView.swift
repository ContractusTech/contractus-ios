//
//  BalanceView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.09.2022.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let noneCoinImage = Image("NONE-CoinLogo")
}

struct BalanceView: View {

    enum BalanceState {
        case empty
        case loaded(Balance)
    }

    struct Coin: Identifiable, Equatable {
        static func == (lhs: BalanceView.Coin, rhs: BalanceView.Coin) -> Bool {
            lhs.id == rhs.id
        }

        var id: String {
            self.amount.currency.code
        }
        let amount: Amount
        var logo: Image {
            guard let image = UIImage(named: "\(self.amount.currency.code)-CoinLogo") else {
                return Constants.noneCoinImage
            }
            return Image(uiImage: image)
        }
    }

    var state: BalanceState = .empty
    var topUpAction: () -> Void

    var body: some View {
        VStack {
            // MARK: - Top
            HStack {
                VStack(alignment: .leading) {
                    switch state {
                    case .empty:
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(4)
                            .frame(width: 100, height: 13, alignment: .leading)
                            .padding(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 200, height: 24, alignment: .leading)

                    case .loaded(let balance):
                        Text("Estimate balance")
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.secondaryText.color)
                        Text(balance.estimateAmountFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(R.color.textBase.color)

                    }

                }
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
//                .overlay(
//                    RoundedRectangle(cornerRadius: 23)
//                        .stroke(R.color.buttonBackgroundPrimary.color, lineWidth: 1)
//                )
            }
            
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 8))

            // MARK: - Coins
            switch state {
            case .empty:
                VStack(alignment: .center) {
                    HStack(alignment: .center, spacing: 12){
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 24, height: 24, alignment: .leading)
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 124, height: 19, alignment: .leading)
                        Spacer()
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 80, height: 19, alignment: .leading)
                    }
                    Divider()
                    HStack(alignment: .center, spacing: 12){
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 24, height: 24, alignment: .leading)
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 124, height: 19, alignment: .leading)
                        Spacer()
                        Rectangle()
                            .fill(R.color.baseSeparator.color)
                            .cornerRadius(8)
                            .frame(width: 80, height: 19, alignment: .leading)
                    }
                }
                .padding()
                .background(R.color.secondaryBackground.color)
                .cornerRadius(16)
            case .loaded(let balance):
                if !balance.coins.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(balance.coins) { coin in
                            HStack(alignment: .center, spacing: 12){
                                coin.logo
                                    .resizable()
                                    .frame(width: 24, height: 24, alignment: .center)
                                Text(coin.amount.currency.code)
                                    .font(.body)
                                    .foregroundColor(R.color.textBase.color)
                                Spacer()
                                Text(coin.amount.formatted())
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            if coin != balance.coins.last { Divider() }
                        }
                    }
                    .padding()
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(16)
                } else {
                    EmptyView()
                }
            }

        }
    }
}

struct BalanceView_Previews: PreviewProvider {

    static var previews: some View {
//        BalanceView(state: .loaded(estimateBalanceFormatted:  "$ 1212.00", coins: [
//            .init(currency: .usdc, balance: "12"),
//            .init(currency: .sol, balance: "1000")
//        ])) {
//            
//        }

        BalanceView(state: .empty) {

        }
    }
}


private extension Balance {

    var estimateAmountFormatted: String {
        Amount("\(self.estimateAmount)", currency: .usd).formatted()
    }
    
    var coins: [BalanceView.Coin] {
        return [
            .init(amount: Amount(self.solAmount, currency: .sol)),
            .init(amount:  Amount("\(self.usdcAmount)", currency: .usdc))
        ]
    }
}
