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
}

struct DealItemView: View {

    let deal: Deal
    let needPayment: Bool

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
                    if needPayment {
                        Constants.iconPayment.resizable()
                            .frame(width: 8, height: 8)
                            .foregroundColor(R.color.yellow.color)
                    } else {
                        Constants.iconReceive.resizable()
                            .frame(width: 8, height: 8)
                            .foregroundColor(R.color.baseGreen.color)

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
        DealItemView(deal: Mock.deal, needPayment: true)
        DealItemView(deal: Mock.deal, needPayment: false)
    }
}


#endif

