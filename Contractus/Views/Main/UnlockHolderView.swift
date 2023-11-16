//
//  UnlockHolderView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let arrowUp = Image(systemName: "arrow.up.right.square")
}

struct UnlockHolderView: View {

    enum UnlockType {
        case buy
        case coinstore
        case raydium
        case pancake
    }

    var action: (UnlockType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(R.string.localizable.unlockHolderTitle())
                    .font(.title.weight(.semibold))
                    .foregroundColor(R.color.textBase.color)
                Spacer()
                R.image.holderCrown.image
            }
            .padding(.top, 12)

            Text(R.string.localizable.unlockHolderSubtitle())
                .font(.callout.weight(.medium))
                .foregroundColor(R.color.secondaryText.color)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 32)
                .padding(.bottom, 15)

            Text(R.string.localizable.unlockHolderMethods())
                .font(.callout.weight(.medium))
                .foregroundColor(R.color.textBase.color)
                .padding(.trailing, 32)
                .padding(.bottom, 6)

            itemView(
                title: R.string.localizable.unlockHolderBuyTitle(),
                subtitle: R.string.localizable.unlockHolderBuyTitle1(),
                description: "",
                isUrl: false
            ) {
                action(.buy)
            }

            itemView(
                title: R.string.localizable.unlockHolderRaydiumTitle(),
                subtitle: R.string.localizable.unlockHolderRaydiumTitle1(),
                description: "",
                isUrl: true
            ) {
                action(.raydium)
            }

            itemView(
                title: R.string.localizable.unlockHolderCoinstoreTitle(),
                subtitle: R.string.localizable.unlockHolderCoinstoreTitle1(),
                description: R.string.localizable.unlockHolderPancakeSubtitle(),
                isUrl: true
            ) {
                action(.coinstore)
            }

            itemView(
                title: R.string.localizable.unlockHolderPancakeTitle(),
                subtitle: R.string.localizable.unlockHolderPancakeTitle1(),
                description: R.string.localizable.unlockHolderPancakeSubtitle(),
                isUrl: true
            ) {
                action(.pancake)
            }

            Spacer()
        }
        .padding(20)
    }
    
    @ViewBuilder
    func itemView(title: String, subtitle: String, description: String, isUrl: Bool, warn: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            ImpactGenerator.light()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(R.color.textBase.color)
                    Text(subtitle)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(R.color.secondaryText.color)
                    Spacer()
                    if isUrl {
                        Constants.arrowUp
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(warn ? R.color.textWarn.color : R.color.secondaryText.color)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, description.isEmpty ? 21 : 16)
            .padding(.horizontal, 16)
            .background(content: {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(R.color.baseSeparator.color, lineWidth: 1)
            })
        }
    }
}

struct UnlockHolderView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockHolderView { _ in }
    }
}
