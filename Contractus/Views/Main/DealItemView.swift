//
//  DealItemView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 03.08.2022.
//

import SwiftUI
import ContractusAPI

private enum Constants {
    static let iconPayment = Image(systemName: "arrow.up.right")
    static let iconReceive = Image(systemName: "arrow.down.left")
    static let iconChecker = Image(systemName: "person.fill.checkmark")
}

struct DealItemView: View {

    enum DealRoleType {
        case receive, pay, checker
    }

    let deal: Deal
    let dealRoleType: DealRoleType

    var body: some View {

        VStack(alignment:.leading, spacing: 24) {
            HStack {
                Text(deal.amountFormatted)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.textBase.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(deal.currency.code)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(R.color.secondaryText.color)

                    switch dealRoleType {
                    case .pay:
                        Constants.iconPayment.resizable()
                            .frame(width: 8, height: 8)
                            .foregroundColor(R.color.yellow.color)
                    case .receive:
                        Constants.iconReceive.resizable()
                            .frame(width: 8, height: 8)
                            .foregroundColor(R.color.baseGreen.color)
                    case .checker:
                        Constants.iconChecker.resizable()
                            .frame(width: 12, height: 8)
                            .foregroundColor(R.color.blue.color)
                    }
                }
                Spacer()

            }

            VStack(alignment:.leading, spacing: 4) {
                Text("With account")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                if let pk = deal.contractorPublicKey {
                    Text(ContentMask.mask(from: pk))
                        .font(.body)
                        .fontWeight(.medium)
                        
                } else {
                    Text(R.string.localizable.commonEmpty())
                        .font(.body)
                        .fontWeight(.medium)
                }
            }

            HStack {
                Text(deal.status.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(deal.statusColor)

            }
        }
        .padding()
        .background(R.color.secondaryBackground.color)
        .cornerRadius(16)
    }

}

private extension Deal {
    var statusColor: Color {
        switch self.status {
        case .finished:
            return R.color.baseGreen.color
        case .canceled:
            return R.color.baseSeparator.color
        case .new:
            return R.color.blue.color
        case .pending:
            return R.color.secondaryText.color
        case .working:
            return R.color.yellow.color
        case .unknown:
            return R.color.secondaryText.color
        }
    }
}

#if DEBUG

import ContractusAPI

struct DealItemView_Previews: PreviewProvider {

    static var previews: some View {
        DealItemView(deal: Mock.deal, dealRoleType: .checker)
        DealItemView(deal: Mock.deal, dealRoleType: .pay)
        DealItemView(deal: Mock.deal, dealRoleType: .receive)
    }
}


#endif

