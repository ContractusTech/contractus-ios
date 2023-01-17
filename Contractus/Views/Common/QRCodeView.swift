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


struct QRCodeView: View {

    enum ViewSize: CGFloat {
        case normal = 230
    }

    private let qrContent: QRCodeUI?
    private let size: ViewSize

    init(content: String, size: ViewSize = .normal) {
        self.size = size
        self.qrContent = QRCodeUI(text: content, errorCorrection: .high)
    }
    var body: some View {
        VStack {
            if let content = qrContent {
                content
                    .components(.everything)
                    .pixelShape(QRCode.PixelShape.Vertical(cornerRadiusFraction: 0.5))
                    .eyeShape(QRCode.EyeShape.Squircle())
                    .foregroundColor(.black)
                    .background(.white)
                    .frame(width: size.rawValue, height:  size.rawValue, alignment: .center)
            } else {
                EmptyView()
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white))

    }
}



struct QRCodeView_Previews: PreviewProvider {

    static var previews: some View {
        HStack{
            QRCodeView(content: "nmM3Sna4sv7LyPF8bF7lMxs/70gYzI0Z8Hth1TQYLevcHYXfGOI8CFt4dhkeQbq9Igwp+GTwPXJI0aJtp1+Wf0Y38r/IudB/E2I+IZ00TQ0=")
        }
        .baseBackground()
        .padding(40)

    }
}

