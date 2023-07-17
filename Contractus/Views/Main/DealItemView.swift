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
    let timeSinceCreated: String
    let checkerAmount: String?

    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            HStack(spacing: 0) {
                statusLabel()
                Spacer()
                Text(timeSinceCreated)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.whiteSeparator.color)
            }
            
            HStack(spacing: 5) {
                Text(amountPrefix + amountFormatted)
                    .font(.title.weight(.regular))
                    .strikethrough(isStrikethrough, color: colorAmountText)
                    .foregroundColor(colorAmountText)
                VStack(alignment: .leading, spacing: 0) {
                    partnerTypeImage()

                    Text(tokenSymbol)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(R.color.secondaryText.color)
                }
                Spacer()
            }
            .padding(.top, 6)
            
            if roleType == .checker && !(checkerAmount ?? "").isEmpty {
                HStack(spacing: 4) {
                    Text(R.string.localizable.dealTextEarning())
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                    Text(checkerAmount ?? "")
                        .font(.footnote)
                        .foregroundColor(R.color.baseGreen.color)
                }
            } else {
                Text(R.string.localizable.dealTextEarning())
                    .font(.footnote)
                    .foregroundColor(.clear)
            }

            VStack(alignment:.leading, spacing: 2) {
                Text(partnerTypeTitle)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(R.color.secondaryText.color)

                if let pk = withPublicKey {
                    Text(ContentMask.mask(from: pk))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(status == .canceled ? R.color.secondaryText.color : R.color.textBase.color)
                        
                } else {
                    Text(R.string.localizable.commonEmpty())
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(status == .canceled ? R.color.secondaryText.color : R.color.textBase.color)
                }
            }
            .padding(.top, 22)
        }
        .padding(EdgeInsets(top: 13, leading: 11, bottom: 16, trailing: 14))
        .background(R.color.secondaryBackground.color)
        .cornerRadius(20)
        .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
    }

    @ViewBuilder
    func statusLabel() -> some View {
        Text(status.statusTitle)
            .font(.footnote.weight(.medium))
            .textCase(.uppercase)
            .foregroundColor(status.statusColor)
    }

    @ViewBuilder
    func roleLabel() -> some View {
        Text(roleType.title)
            .font(.footnote.weight(.medium))
            .textCase(.uppercase)
            .foregroundColor(roleType.color)
    }

    private var isStrikethrough: Bool {
        return status == .canceled
    }

    private var colorAmountText: Color {
        switch status {
        case .canceled:
            return R.color.secondaryText.color
        case .finished:
            return roleType == .receive ? R.color.baseGreen.color : R.color.textBase.color
        case .new, .pending, .working, .unknown, .inProcessing:
            return R.color.textBase.color
        }
    }

    private var amountPrefix: String {
        return status == .finished && roleType == .receive
        ? "+"
        : ""
    }

    private var partnerTypeTitle: String {
        switch roleType {
        case .receive, .checker:
            return R.string.localizable.dealTextClient()
        case .pay:
            return R.string.localizable.dealTextExecutor()
        }
    }
    
    @ViewBuilder
    func partnerTypeImage() -> some View {
        switch roleType {
        case .receive:
            Constants.iconReceive
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(R.color.baseGreen.color)
        case .checker:
            Constants.iconReceive
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(R.color.whiteSeparator.color)
        case .pay:
            Constants.iconPayment
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(R.color.secondaryText.color)
        }
    }
}

private extension DealItemView.DealRoleType {
    var title: String {
        switch self {
        case .checker:
            return R.string.localizable.dealTextChecker()
        case .pay:
            return R.string.localizable.dealTextClient()
        case .receive:
            return R.string.localizable.dealTextExecutor()
        }
    }
}

private extension DealItemView.DealRoleType {
    var color: Color {
        return R.color.secondaryText.color
//        switch self {
//        case .checker:
//            return R.color.secondaryText.color
//        case .pay:
//            return R.color.textBase.color
//        case .receive:
//            return R.color.textWarn.color
//        }
    }
}

private extension DealStatus {
    var statusColor: Color {
        switch self {
        case .finished:
            return R.color.baseGreen.color
        case .canceled:
            return R.color.redText.color
        case .new:
            return R.color.blue.color
        case .pending, .inProcessing:
            return R.color.secondaryText.color
        case .working:
            return R.color.textBase.color
        case .unknown:
            return R.color.secondaryText.color
        }
    }

    var statusTitle: String {
        switch self {
        case .finished:
            return R.string.localizable.dealStatusFinished()
        case .canceled:
            return R.string.localizable.dealStatusCanceled()
        case .new:
            return R.string.localizable.dealStatusNew()
        case .pending:
            return R.string.localizable.dealStatusPending()
        case .working:
            return R.string.localizable.dealStatusWorking()
        case .unknown:
            return R.string.localizable.dealStatusUnknown()
        case .inProcessing:
            return R.string.localizable.dealStatusProcessing()
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
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .canceled,
                    roleType: .checker,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .new,
                    roleType: .receive,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .working,
                    roleType: .pay,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .finished,
                    roleType: .receive,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .finished,
                    roleType: .pay,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .inProcessing,
                    roleType: .pay,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)

                DealItemView(
                    amountFormatted: Mock.deal.amountFormattedShort,
                    tokenSymbol: Mock.deal.token.code,
                    withPublicKey: Mock.deal.contractorPublicKey,
                    status: .pending,
                    roleType: .pay,
                    timeSinceCreated: Mock.deal.createdAt.relativeDateFormatted,
                    checkerAmount: Mock.deal.amountFeeCheckerFormatted)
            }
        }
        .padding(.horizontal, 100)
        .baseBackground()
    }
}


#endif

