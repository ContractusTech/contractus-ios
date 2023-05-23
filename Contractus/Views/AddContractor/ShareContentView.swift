//
//  ShareContentView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.09.2022.
//

import SwiftUI
import protocol ContractusAPI.Shareable

fileprivate enum Constants {
    static let warningImage = "exclamationmark.square.fill"
    static let successImage = "checkmark.seal.fill"
}

struct ShareContentView: View {

    @Environment(\.presentationMode) var presentationMode

    private let topTitle: String?
    private let title: String
    private let subTitle: String?
    private let topImage: Image?
    private let rawContent: String
    private let copyAction: (String) -> Void
    private let dismissAction: () -> Void
    private let contentType: CopyContentView.ContentType
    private let informationType: TopTextBlockView.InformationType

    init(
        contentType: CopyContentView.ContentType = .publicKey,
        informationType: TopTextBlockView.InformationType = .none,
        content: Shareable,
        topTitle: String?,
        title: String,
        subTitle: String? = nil,
        topImage: Image? = nil,
        copyAction: @escaping (String) -> Void,
        dismissAction: @escaping () -> Void)
    {
        self.rawContent = content.shareContent
        self.copyAction = copyAction
        self.topTitle = topTitle
        self.title = title
        self.subTitle = subTitle
        self.topImage = topImage
        self.dismissAction = dismissAction
        self.contentType = contentType
        self.informationType = informationType
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack {
                    TopTextBlockView(
                        informationType: informationType,
                        headerText: topTitle,
                        titleText: title,
                        subTitleText: subTitle ?? "")

                    QRCodeView(content: rawContent)

                    Text(R.string.localizable.shareNote())
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                        .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))

                    CopyContentView(content: rawContent, contentType: contentType) { value in
                        UIPasteboard.general.string = value
                        copyAction(value)
                    }
                }
            }

            CButton(
                title: R.string.localizable.commonClose(),
                style: .secondary,
                size: .large,
                isLoading: false)
            {
                // presentationMode.wrappedValue.dismiss()
                dismissAction()
            }

        }

        .baseBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: UIConstants.bottomInset, trailing: 16))
        .edgesIgnoringSafeArea(.bottom)
        .baseBackground()

    }
}

#if DEBUG
import struct ContractusAPI.ShareableDeal

struct ShareSecretView_Previews: PreviewProvider {
    static var previews: some View {
        ShareContentView( content: ShareableDeal(dealId: "", secretBase64: ""), topTitle: "New title", title: "Share some data", subTitle: "Some text describe sharable content") { _ in

        } dismissAction: {

        }

    }
}

#endif
