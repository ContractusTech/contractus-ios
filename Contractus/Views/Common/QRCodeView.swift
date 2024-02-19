import Foundation
import ContractusAPI
import SwiftUI
import QRCode

struct QRCodeView: View {

    enum ViewSize: CGFloat {
        case normal = 230
    }

    private let content: String
    private let size: ViewSize

    init(content: String, size: ViewSize = .normal) {
        self.size = size
        self.content = content
    }
    var body: some View {
        VStack {

            QRCodeViewUI(
                content: content,
                errorCorrection: .high,
                foregroundColor: Color.black.cgColor!,
                backgroundColor: Color.white.cgColor!,
                pixelStyle: QRCode.PixelShape.Vertical(cornerRadiusFraction: 0.2),
                eyeStyle: QRCode.EyeShape.Squircle()
            )
            .frame(width: size.rawValue, height:  size.rawValue, alignment: .center)
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

