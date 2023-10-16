//
//  BalanceView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.09.2022.
//

import SwiftUI
import ContractusAPI
import BigInt
import Shimmer

fileprivate enum Constants {
    static let noneCoinImage = Image("NONE-CoinLogo")
    static let swapImage = Image(systemName: "arrow.triangle.swap")
    static let infoImage = Image(systemName: "info.circle.fill")
    static let arrowUp = Image(systemName: "chevron.up")
    static let settings = Image(systemName: "slider.horizontal.3")
}

struct BalanceViewModel {

    struct WrapTokens {
        let tokens: [Balance.TokenInfo]
    }

    let estimateAmountFormatted: String
    let wrap: WrapTokens
    let servicedToken: Balance.TokenInfo?
    let tokens: [Balance.TokenInfo]
    let tier: Balance.Tier
    var canWrap: Bool {
        wrap.tokens.count == 2
    }

    init(balance: Balance, currency: Currency = .defaultCurrency) {
        estimateAmountFormatted = currency.format(double: balance.estimateAmount, withCode: true) ?? ""
        var tokens: [Balance.TokenInfo] = []
        var wrap: [Balance.TokenInfo] = []
        var servicedToken: Balance.TokenInfo?
        balance.tokens.forEach { item in
            if servicedToken == nil && item.amount.token.serviced {
                servicedToken = item
                return
            }
            if balance.wrap.contains(item.amount.token.code) {
                wrap.append(item)
            } else {
                tokens.append(item)
            }
        }
        self.servicedToken = servicedToken
        self.wrap = .init(tokens: wrap)
        self.tokens = tokens
        self.tier = balance.tier
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
            self.amount.token.address ?? self.amount.token.code
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
    var infoAction: () -> Void
    var swapAction: (Amount, Amount) -> Void
    var settingsAction: () -> Void

    @State private var isTokensVisible = FlagsStorage.shared.mainTokensVisibility

    var body: some View {
        VStack {
            // MARK: - Top
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch state {
                    case .empty:
                        Rectangle()
                            .fill(R.color.thirdBackground.color)
                            .cornerRadius(4)
                            .frame(width: 100, height: 13, alignment: .leading)
                            .padding(0)
                            .shimmering()
                        
                        Rectangle()
                            .fill(R.color.thirdBackground.color)
                            .cornerRadius(8)
                            .frame(width: 140, height: 29, alignment: .leading)
                            .shimmering()

                        Rectangle()
                            .cornerRadius(8)
                            .frame(width: 0, height: 10, alignment: .leading)
                            .shimmering()

                    case .loaded(let balance):
                        Text(R.string.localizable.balanceTitle())
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.secondaryText.color)
                        Text(balance.estimateAmountFormatted)
                            .font(.largeTitle.weight(SwiftUI.Font.Weight.light))
                            .foregroundColor(R.color.textBase.color)
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
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
                                .shimmering()
                            Spacer()
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 80, height: 16, alignment: .leading)
                                .shimmering()
                        }
                        .padding(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
                        Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                        HStack(alignment: .center, spacing: 12){
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 124, height: 16, alignment: .leading)
                                .shimmering()
                            Spacer()
                            Rectangle()
                                .fill(R.color.mainBackground.color)
                                .cornerRadius(8)
                                .frame(width: 80, height: 16, alignment: .leading)
                                .shimmering()
                        }
                        .padding(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 4))
                    }
                    .padding(8)
                    .background(R.color.secondaryBackground.color)
                    .cornerRadius(16)
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

            case .loaded(let balance):
                Divider()
                    .overlay(isTokensVisible ? R.color.mainBackground.color : R.color.buttonBorderSecondary.color)
                HStack {

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTokensVisible.toggle()
                            FlagsStorage.shared.mainTokensVisibility = isTokensVisible
                        }
                    } label: {
                        HStack {
                            Text(R.string.localizable.commonTokens())
                                .font(.footnote.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundColor(R.color.secondaryText.color)
                            Constants.arrowUp
                                .resizable()
                                .scaledToFit()
                                .frame(width: 10, height: 10)
                                .rotationEffect(.degrees(isTokensVisible ? 0 : 180))
                                .foregroundColor(R.color.textBase.color)
                                .padding(6)
                                .background(R.color.secondaryBackground.color)
                                .cornerRadius(10)
                        }
                    }
                    Spacer()

                    Button {
                        settingsAction()
                    } label: {
                        Constants.settings
                            .frame(width: 24, height: 24)
                            .foregroundColor(R.color.buttonTextSecondary.color)
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                if isTokensVisible {
                    VStack(spacing: 4) {

                        if let token = balance.servicedToken {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .center, spacing: 4){
                                    Text(token.amount.token.code)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(R.color.textBase.color)


                                    if token.price > 0 {
                                        Text(token.priceFormattedWithCode)
                                            .font(.footnote.weight(.semibold))
                                            .textCase(.uppercase)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Button {
                                            infoAction()
                                        } label: {
                                            Constants.infoImage
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(R.color.secondaryText.color)
                                        }
                                        Text(token.amount.valueFormatted)
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(R.color.textBase.color)
                                    }

                                }
                                .padding(EdgeInsets(top: 16, leading: 10, bottom: 16, trailing: 10))
                            }
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(16)
                            .padding(0)
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                        }

                        if !balance.wrap.tokens.isEmpty {
                            ZStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(balance.wrap.tokens, id: \.id) { token in
                                        HStack(alignment: .center, spacing: 4) {
                                            Text(token.amount.token.code)
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.textBase.color)
                                            if token.price > 0 {
                                                Text(token.priceFormattedWithCode)
                                                    .font(.footnote.weight(.semibold))
                                                    .textCase(.uppercase)
                                                    .foregroundColor(R.color.secondaryText.color)
                                            }

                                            Spacer()
                                            Text(token.amount.valueFormatted)
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.textBase.color)
                                        }
                                        .padding(EdgeInsets(top: 16, leading: 10, bottom: 16, trailing: 10))
                                        if token.amount.token.code != balance.wrap.tokens.last?.amount.token.code { Divider().foregroundColor(R.color.buttonBorderSecondary.color) }
                                    }
                                }
                                .background(R.color.secondaryBackground.color)
                                .cornerRadius(16)
                                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                                if balance.canWrap {
                                    Button {
                                        swapAction(balance.wrap.tokens.first!.amount, balance.wrap.tokens.last!.amount)
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
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(balance.tokens, id: \.id) { token in
                                    HStack(alignment: .center, spacing: 4){
                                        Text(token.amount.token.code)
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(R.color.textBase.color)
                                        if token.price > 0 {
                                            Text(token.priceFormattedWithCode)
                                                .font(.footnote.weight(.semibold))
                                                .textCase(.uppercase)
                                                .foregroundColor(R.color.secondaryText.color)
                                        }
                                        Spacer()
                                        Text(token.amount.valueFormatted)
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(R.color.textBase.color)
                                    }
                                    .padding(EdgeInsets(top: 16, leading: 10, bottom: 16, trailing: 10))
                                    if token.amount.token.code != balance.tokens.last?.amount.token.code { Divider().foregroundColor(R.color.buttonBorderSecondary.color) }
                                }
                            }
                            .background(R.color.secondaryBackground.color)
                            .cornerRadius(16)
                            .padding(0)
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0, anchor: UnitPoint(x: 0.5, y: -0.1)),
                        removal: .scale(scale: 0, anchor: UnitPoint(x: 0.5, y: -0.1)))
                    )
                }
                Divider()
                    .overlay(isTokensVisible ? R.color.mainBackground.color : R.color.buttonBorderSecondary.color)
            }

        }
    }
}

extension Amount: Identifiable {
    public var id: String {
        self.token.address ?? self.token.code
    }
}

extension Balance.TokenInfo: Identifiable {
    public var id: String {
        self.amount.id
    }
}

struct BalanceView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            BalanceView(state: .loaded(.init(balance: .init(estimateAmount: 14.0, tokens: [.init(price: 0, currency: .defaultCurrency, amount: .init(.init("0"), token: Mock.tokenSOL))], blockchain: "solana", wrap: ["SOL", "WSOL"], tier: .basic)))) {

            } infoAction: { } swapAction: { _, _ in

            } settingsAction: {

            }

            BalanceView(state: .empty) {

            } infoAction: { } swapAction: { _, _ in

            } settingsAction: {

            }
        }
        .baseBackground()
        .preferredColorScheme(.light)

        VStack {
            BalanceView(state: .loaded(.init(balance: .init(estimateAmount: 14.0, tokens: [.init(price: 0, currency: .defaultCurrency, amount: .init(.init("0"), token: Mock.tokenSOL))], blockchain: "solana", wrap: ["SOL", "WSOL"], tier: .basic)))) {

            } infoAction: { } swapAction: { _, _ in

            } settingsAction: {

            }

            BalanceView(state: .empty) {

            } infoAction: { } swapAction: { _, _ in

            } settingsAction: {

            }
        }
        .baseBackground()
        .preferredColorScheme(.dark)


    }
}
