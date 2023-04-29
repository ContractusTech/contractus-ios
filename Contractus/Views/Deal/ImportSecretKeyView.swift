//
//  ImportSecretKeyView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.10.2022.
//

import SwiftUI
import ContractusAPI

private enum Constants {
    static let importImage = Image(systemName: "key.fill")
}

struct ImportSecretKeyView: View {

    @State var secretKey: String = ""
    let blockchain: Blockchain
    var action: (String?) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Constants.importImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .foregroundColor(R.color.textBase.color)

                VStack(alignment: .center, spacing: 8) {
                    Text("Import secret key")
                        .font(.title)
                    Text("Owner must send key to you or allow scan\nQR code")
                        .font(.callout)
                        .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.center)
                }

                TextFieldView(
                    placeholder: "Enter key",
                    blockchain: blockchain,
                    value: secretKey) { result in
                        self.secretKey = result
                }

                Spacer()
                LargePrimaryLoadingButton(
                    action: {
                        action(self.secretKey)
                    },
                    isLoading: false) {
                        HStack {
                            Spacer()
                            Text(R.string.localizable.commonImport())
                            Spacer()
                        }
                    }
                    .disabled(self.secretKey.isEmpty)
            }
            .baseBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding()
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)

    }
}

#if DEBUG
struct ImportSecretKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportSecretKeyView(blockchain: .solana) { key in
            
        }
    }
}
#endif
