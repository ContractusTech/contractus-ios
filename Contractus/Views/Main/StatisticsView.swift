//
//  StatisticsView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 13.05.2023.
//

import SwiftUI
import struct ContractusAPI.AccountStatistic

fileprivate enum Constants {
    static let infoImage = Image(systemName: "info.circle.fill")
}

struct StatisticsItemView: View {

    let item: AccountStatistic
    var infoTapAction: ((AccountStatistic) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.title)
                    .font(.footnote)
                    .foregroundColor(R.color.secondaryText.color)
                if item.displayInfoIcon {
                    Button {
                        infoTapAction?(item)
                    } label: {
                        Constants.infoImage
                            .resizable()
                            .frame(width: 16, height: 16)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }
                Spacer()
            }
            Text(item.value)
                .foregroundColor(item.valueColor)
                .font(.body.weight(.medium))
        }
        .frame(minWidth: 120)
        .padding(12)
        .background(R.color.secondaryBackground.color)
        .cornerRadius(20)
        .shadow(color: R.color.shadowColor.color.opacity(0.2), radius: 4)

    }
}

struct StatisticsView: View {

    struct Item: Identifiable {
        var id: String { type }

        let type: String
        let title: String
        let value: String
        let valueColor: Color
        let displayInfoIcon: Bool
    }

    let items: [AccountStatistic]
    var infoTapAction: ((AccountStatistic) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(items, id: \.id) { item in
                    StatisticsItemView(item: item) { tapItem in
                        infoTapAction?(tapItem)
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }
}

extension AccountStatistic: Identifiable {
    public var id: String { type.rawValue }

    var title: String {
        switch type {
        case .locked:
            return R.string.localizable.mainStatisticsLocked()
        case .paid30d:
            return R.string.localizable.mainStatisticsPaid30()
        case .paidAll:
            return R.string.localizable.mainStatisticsPaidAll()
        case .revenue30d:
            return R.string.localizable.mainStatisticsRevenue30()
        case .revenueAll:
            return R.string.localizable.mainStatisticsRevenueAll()
        }
    }

    var value: String {
        guard let amountFormatted = currency.format(double: self.amount) else {
            return "–"
        }
        if self.amount > 0 {
            return "≈ \(amountFormatted)"
        } else {
            return amountFormatted
        }

    }

    var valueColor: Color {
        switch type {
        case .paidAll, .paid30d:
            return amount > 0 ? R.color.textBase.color : R.color.secondaryText.color
        case .locked:
            return R.color.textBase.color
        case .revenue30d, .revenueAll:
            return amount > 0 ? R.color.baseGreen.color : R.color.secondaryText.color
        }
    }

    var displayInfoIcon: Bool {
        switch type {
        case .locked:
            return true
        default:
            return false
        }
    }
}


struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(items: [
            .init(type: .revenueAll, amount: 1.0, currency: .USD),
            .init(type: .revenue30d, amount: 1000.0, currency: .USD)
        ])
        .baseBackground()
    }
}
