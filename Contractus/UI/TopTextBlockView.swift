//
//  TopTextBlockView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.11.2022.
//

import SwiftUI

private enum Constants {
    static let successImage = Image(systemName: "checkmark.seal.fill")
    static let warningImage = Image(systemName: "exclamationmark.octagon")
    static let waitingImage = Image(systemName: "clock.fill")
}

struct TopTextBlockView: View {

    enum InformationType {
        case none, success, warning, waiting

        var image: Image? {
            switch self {
            case .success:
                return Constants.successImage
            case .warning:
                return Constants.warningImage
            case .waiting:
                return Constants.waitingImage
            case .none:
                return nil
            }
        }

        var textColor: Color {
            switch self {
            case .success:
                return R.color.white.color
            case .none:
                return R.color.labelTextAttention.color.opacity(0.7)
            case .warning:
                return R.color.white.color.opacity(0.9)
            case .waiting:
                return R.color.white.color
            }
        }

        var background: Color {
            switch self {
            case .success:
                return R.color.baseGreen.color
            case .none:
                return R.color.labelBackgroundDefault.color
            case .warning:
                return R.color.labelBackgroundError.color
            case .waiting:
                return R.color.secondaryText.color
            }
        }
    }

    var informationType: InformationType = .none
    let headerText: String?
    let titleText: String
    let subTitleText: String?

    var body: some View {
        VStack(spacing: 0) {
            if let headerText = headerText, !headerText.isEmpty {
                HStack {
                    Spacer()
                    HStack {
                        if let image = informationType.image {
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(informationType.textColor)
                        }
                        Text(headerText)
                            .multilineTextAlignment(.center)
                            .font(.footnote.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundColor(informationType.textColor)
                    }
                    .padding(EdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7))
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20).fill(informationType.background)
                            RoundedRectangle(cornerRadius: 20).stroke().fill(R.color.textBase.color.opacity(0.07))
                        }
                    }
//                    .cornerRadius(20)
                    Spacer()
                }
                .padding(EdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0))
            }
            HStack {
                Spacer()
                Text(titleText)
                    .font(.largeTitle.weight(.semibold))
                    .tracking(-1.1)
                Spacer()
            }
            if let subTitleText = subTitleText {
                HStack {
                    Spacer()
                    Text(subTitleText)
                        .font(.callout)
                        // .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20))
                    Spacer()
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 21, trailing: 16))
    }
}

struct TopTextBlockView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                TopTextBlockView(
                    informationType: .none,
                    headerText: "Import",
                    titleText: "Enter private key",
                    subTitleText: "Of the client who will perform the work under the contract.")

                TopTextBlockView(
                    informationType: .success,
                    headerText: "Import",
                    titleText: "Enter private key",
                    subTitleText: "Of the client who will perform the work under the contract.")

                TopTextBlockView(
                    informationType: .waiting,
                    headerText: "In progress",
                    titleText: "Enter private key",
                    subTitleText: "Of the client who will perform the work under the contract.")

                TopTextBlockView(
                    informationType: .warning,
                    headerText: "Import",
                    titleText: "Enter private key",
                    subTitleText: "Of the client who will perform the work under the contract.")
            }
        }
    }
}
