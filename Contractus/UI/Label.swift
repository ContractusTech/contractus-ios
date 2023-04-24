//
//  Label.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.08.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
}

struct Label: View {

    enum TypeLabel {
        case `default`, success, primary, attention
    }

    enum LabelSize {
        case small
    }

    let text: String
    let type: TypeLabel
    let size: LabelSize = .small

    var body: some View {
        content()
    }

    @ViewBuilder
    func content() -> some View {
        HStack(spacing: 2) {
            switch type {
            case .success:
                Constants.checkmarkImage
                    .resizable()
                    .frame(width: imageSize, height: imageSize, alignment: .center)
                    .foregroundColor(foreground)
            case .default, .primary, .attention:
                EmptyView()
            }
            Text(text)
                .font(font)
                .foregroundColor(foreground)

        }
        .padding(padding)
        .background(background)
        .cornerRadius(corner)

    }

    var font: Font {
        switch size {
        case .small:
            return .system(size: 12)
        }
    }

    var padding: EdgeInsets {
        switch size {
        case .small:
            return .init(top: 2, leading: 8, bottom: 2, trailing: 8)
        }
    }
    var corner: Double {
        switch size {
        case .small:
            return 16
        }
    }

    var imageSize: Double {
        switch size {
        case .small:
            return 8
        }
    }

    var foreground: Color {
        switch type {
        case .default:
            return R.color.secondaryText.color
        case .success:
            return R.color.labelTextSuccess.color
        case .primary:
            return R.color.labelTextPrimary.color
        case .attention:
            return R.color.labelTextAttention.color
        }
    }

    var background: Color {
        switch type {
        case .default:
            return R.color.labelBackgroundDefault.color
        case .success:
            return R.color.labelBackgroundSuccess.color
        case .primary:
            return R.color.labelBackgroundPrimary.color
        case .attention:
            return R.color.labelBackgroundAttention.color
        }
    }
}

struct Label_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Label(text: "Signed", type: .default)
                Label(text: "Test", type: .success)
                Label(text: "Test", type: .primary)
                Label(text: "Test", type: .attention)
            }
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Light theme")
        Group {
            VStack {
                VStack {
                    Label(text: "Signed", type: .default)
                    Label(text: "Test", type: .success)
                    Label(text: "Test", type: .primary)
                    Label(text: "Test", type: .attention)
                }
                .padding(20)
                .baseBackground()

                VStack {
                    Label(text: "Signed", type: .default)
                    Label(text: "Test", type: .success)
                    Label(text: "Test", type: .primary)
                    Label(text: "Test", type: .attention)
                }
                .padding(20)
                .background(R.color.secondaryBackground.color)
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark theme")
    }
}
