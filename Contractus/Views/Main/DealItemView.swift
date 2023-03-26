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

fileprivate let SIZE_BLOCK: CGFloat = 110
struct DealItemView: View {

    enum DealRoleType {
        case receive, pay, checker
    }

    let amountFormatted: String
    let tokenSymbol: String
    let withPublicKey: String?
    let status: DealStatus
    let roleType: DealRoleType

    var body: some View {

        VStack(alignment:.leading, spacing: 12) {

            ZStack(alignment: .leading) {
                HStack {
                    statusLabel()
                    Spacer()
                    roleLabel()

                }
                .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                .offset(x: 0, y: -(SIZE_BLOCK / 2 - 16))

                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        Spacer()
                        Text(amountFormatted)
                            .font(.title)
                            .fontWeight(.medium)
                            .strikethrough(isStrikethrough, color: colorAmountText)
                            .foregroundColor(colorAmountText)
                        Spacer()
                    }
                    Text(tokenSymbol)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(R.color.secondaryText.color)
                }
                .offset(CGSize(width: 0, height: 6))
            }
            .frame(height: SIZE_BLOCK)
            .baseBackground()
            .cornerRadius(18)


            VStack(alignment:.leading, spacing: 2) {
                Text(partnerTypeTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)

                if let pk = withPublicKey {
                    Text(ContentMask.mask(from: pk))
                        .font(.body)
                        .fontWeight(.medium)
                        
                } else {
                    Text(R.string.localizable.commonEmpty())
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
        }
        .padding(6)
        .background(R.color.secondaryBackground.color)
        .cornerRadius(20)
    }

    @ViewBuilder
    func statusLabel() -> some View {
        Text(status.statusTitle)
            .font(.caption)
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            .background(status.statusColor)
            .foregroundColor(R.color.white.color)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)

    }

    @ViewBuilder
    func roleLabel() -> some View {
        Text(roleType.title)
            .font(.caption)
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            .background(R.color.secondaryBackground.color)
            .foregroundColor(R.color.textBase.color)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)

    }

    private var isStrikethrough: Bool {
        return status == .canceled
    }

    private var colorAmountText: Color {
        switch status {
        case .canceled:
            return R.color.secondaryText.color
        case .finished:
            return R.color.baseGreen.color
        case .new, .pending, .working, .unknown, .inProcessing:
            return R.color.textBase.color
        }
    }

    private var partnerTypeTitle: String {
        switch roleType {
        case .receive, .checker:
            return "For client"
        case .pay:
            return "Executor"
        }
    }

}

private extension DealItemView.DealRoleType {
    var title: String {
        switch self {
        case .checker:
            return "Checker"
        case .pay:
            return "Client"
        case .receive:
            return "Executor"
        }
    }
}

private extension DealStatus {
    var statusColor: Color {
        switch self {
        case .finished:
            return R.color.baseGreen.color
        case .canceled:
            return R.color.secondaryText.color
        case .new:
            return R.color.blue.color
        case .pending, .inProcessing:
            return R.color.secondaryText.color
        case .working:
            return R.color.yellow.color
        case .unknown:
            return R.color.secondaryText.color
        }
    }

    var statusTitle: String {
        switch self {
        case .finished:
            return "Finished"
        case .canceled:
            return "Canceled"
        case .new:
            return "New"
        case .pending:
            return "Pending"
        case .working:
            return "In work"
        case .unknown:
            return "-"
        case .inProcessing:
            return "Processing"
        }
    }
}

#if DEBUG

import ContractusAPI

struct DealItemView_Previews: PreviewProvider {

    static var previews: some View {
        ScrollView {
            VStack {
                DealItemView(
                    amountFormatted: Mock.deal.amountFormatted,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .canceled,
                    roleType: .checker)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormatted,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .new,
                    roleType: .receive)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormatted,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .working,
                    roleType: .pay)
            }

        }.padding(120)
            .baseBackground()



    }
}


#endif

