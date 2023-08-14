//
//  TextFieldView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.10.2022.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let qrScanIcon = Image(systemName: "qrcode.viewfinder")
    static let contactIcon = Image(systemName: "person.fill.badge.plus")
}

struct TextFieldView: View {

    let placeholder: String
    let blockchain: Blockchain

    var allowQRScan: Bool = true
    
    @State var value: String = ""
    @State private var isPresentedQRScan = false
    var changeValue: (String) -> Void
    var onQRTap: (() -> Void)?

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
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
            if allowQRScan {
                Button {
                    isPresentedQRScan.toggle()
                    onQRTap?()
                } label: {
                    Constants.qrScanIcon
                        .resizable()
                        .frame(width: 28, height: 28, alignment: .center)
                        .foregroundColor(R.color.textBase.color)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                }
            }
        }
        .background(R.color.textFieldBackground.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(R.color.textFieldBorder.color, lineWidth: 1)
        )
        .sheet(isPresented: $isPresentedQRScan) {
            QRCodeScannerView(configuration: .onlyScanner, blockchain: blockchain) { result in
                isPresentedQRScan.toggle()
                switch result {
                case .deal(let deal):
                    // TODO: -
                    break
                case .publicKey(let pk):
                    value = pk
                    changeValue(pk)
                }
            }
        }
    }
}

struct TextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldView(placeholder: "Enter value", blockchain: .solana, changeValue: { _ in

        })
    }
}
