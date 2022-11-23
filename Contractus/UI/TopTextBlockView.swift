//
//  TopTextBlockView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 23.11.2022.
//

import SwiftUI

struct TopTextBlockView: View {

    enum InformationType {
        case none, success, warning

        var image: Image? {
            switch self {
            case .success:
                return Image(systemName: "checkmark.seal.fill")
            case .warning:
                return Image(systemName: "exclamationmark.octagon")
            case .none:
                return nil
            }
        }

        var color: Color {
            switch self {
            case .success:
                return R.color.baseGreen.color
            case .none:
                return R.color.secondaryText.color
            case .warning:
                return R.color.yellow.color
            }
        }
    }

    var informationType: InformationType = .none
    let headerText: String
    let titleText: String
    let subTitleText: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let image = informationType.image {
                    image.resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(informationType.color)
                }
                Text(headerText)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundColor(informationType.color)
            }


            Text(titleText)
                .font(.largeTitle.weight(.heavy))
            Text(subTitleText)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
    }
}

struct TopTextBlockView_Previews: PreviewProvider {
    static var previews: some View {

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
            informationType: .warning,
            headerText: "Import",
            titleText: "Enter private key",
            subTitleText: "Of the client who will perform the work under the contract.")
    }
}
