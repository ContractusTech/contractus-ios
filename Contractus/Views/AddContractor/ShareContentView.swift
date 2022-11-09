//
//  ShareContentView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.09.2022.
//

import SwiftUI
import QRCode
import protocol ContractusAPI.Shareable

fileprivate enum Constants {
    static let warningImage = "exclamationmark.square.fill"
    static let successImage = "checkmark.seal.fill"
}

struct ShareContentView: View {

    enum ContextType {
        case afterAdded(title: String)
        case share
    }

    @Environment(\.presentationMode) var presentationMode

    private let title: String
    private let subTitle: String?
    private let topImage: Image?
    private var qrContent: QRCodeUI?
    private let rawContent: String
    private let copyAction: (String) -> Void
    private let closeAction: () -> Void

    init(
        content: Shareable,
        title: String,
        subTitle: String? = nil,
        topImage: Image? = nil,
        copyAction: @escaping (String) -> Void,
        closeAction: @escaping () -> Void)
    {
        self.rawContent = content.shareContent()
        self.qrContent = QRCodeUI(text: rawContent, errorCorrection: .low)
        self.copyAction = copyAction
        self.title = title
        self.subTitle = subTitle
        self.topImage = topImage
        self.closeAction = closeAction
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack {
                if let topImage = topImage {
                    topImage
                        .resizable()
                        .frame(width: 42, height: 42, alignment: .center)
                        .foregroundColor(R.color.baseGreen.color)
                }

                VStack(spacing: 16) {
                    Text(title)
                        .font(.title)
                    if let subTitle = subTitle {
                        Text(subTitle).font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                }

                if let content = qrContent {
                    content
                        .components(.everything)
                        .pixelShape(QRCode.PixelShape.RoundedPath())
                        .frame(width: 210, height: 210, alignment: .center)
                        .background(R.color.secondaryBackground.color)
                        .padding()


                } else {
                    EmptyView()
                }



                Text("Or you can send this value to a partner any way you like")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .padding(EdgeInsets(top: 24, leading: 0, bottom: 0, trailing: 0))

                CopyContentView(content: rawContent, contentType: .common) { value in
                    UIPasteboard.general.string = value
                    copyAction(value)
                }
                Spacer()
                Button {
                    closeAction()
                } label: {
                    HStack {
                        Spacer()
                        Text(R.string.localizable.commonClose())
                        Spacer()
                    }
                }
                .buttonStyle(SecondaryLargeButton())
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 42, trailing: 16))
        }
        .baseBackground()
        .navigationBarBackButtonHidden(true)
        .edgesIgnoringSafeArea(.bottom)

    }
}

#if DEBUG
import struct ContractusAPI.ShareableDeal

struct ShareSecretView_Previews: PreviewProvider {
    static var previews: some View {
        ShareContentView(content: ShareableDeal(dealId: "", secretBase64: ""), title: "Share Secret") { _ in

        } closeAction: {

        }

    }
}

#endif
