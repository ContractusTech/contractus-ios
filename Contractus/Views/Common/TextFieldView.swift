//
//  TextFieldView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.10.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let qrScanIcon = Image(systemName: "qrcode.viewfinder")
    static let contactIcon = Image(systemName: "person.fill.badge.plus")
}

struct TextFieldView: View {

    let placeholder: String
    @State var value: String = ""
    @State private var isPresentedQRScan = false
    var changeValue: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $value)
                .textFieldStyle(LargeTextFieldStyle())
                .onChange(of: value) { newValue in
                    changeValue(newValue)
                }
            Button {
                value = UIPasteboard.general.string ?? ""
            } label: {
                Text(R.string.localizable.commonPaste())
                    .foregroundColor(R.color.textBase.color)
                    .font(.body.weight(.medium))
            }

            Button {
                isPresentedQRScan.toggle()
            } label: {
                Constants.qrScanIcon
                    .resizable()
                    .frame(width: 28, height: 28, alignment: .center)
                    .foregroundColor(R.color.textBase.color)
                    .padding(12)
            }
        }
        .background(R.color.baseSeparator.color)
        .cornerRadius(12)
        .sheet(isPresented: $isPresentedQRScan) {
            QRScannerView()
        }
    }
}

struct TextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldView(placeholder: "Enter value", changeValue: { _ in

        })
    }
}
