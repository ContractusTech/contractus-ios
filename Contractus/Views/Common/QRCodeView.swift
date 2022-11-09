//
//  QRCodeView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 05.08.2022.
//

import Foundation
import ContractusAPI
import SwiftUI
import QRCode

fileprivate enum Constants {
    static let warningImage = "exclamationmark.square.fill"
}
struct QRCodeView: View {
    var qrContent: QRCodeUI?

    init(content: String) {
        qrContent = QRCodeUI(text: content, errorCorrection: .low)
    }
    var body: some View {
        VStack {
            if let content = qrContent {
                content
                    .components(.everything)
                    .pixelShape(QRCode.PixelShape.Vertical())
                    .frame(width: 300, height: 300, alignment: .center)
                    .padding()

            } else {
                EmptyView()
            }

            Spacer()
            HStack {
                Image(systemName: Constants.warningImage)
                Text(R.string.localizable.qrCodeWarningMessage())

            }
            .padding()
            .background(R.color.thirdBackground.color)
            .cornerRadius(10)

            Button {

            } label: {
                HStack {
                    Spacer()
                    Text(R.string.localizable.qrCodeButtonShare())
                    Spacer()
                }

            }.buttonStyle(PrimaryLargeButton())
        }
        .padding()
    }
}



struct QRCodeView_Previews: PreviewProvider {

    static var previews: some View {
        QRCodeView(content: "Content")
    }
}

