//
//  SecretKeyScannerView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.11.2022.
//

import SwiftUI
import CodeScanner
import ContractusAPI

struct QRCodeScannerView: View {

    enum Configuration {
        case scannerAndInput, onlyScanner
    }

    let configuration: Configuration
    var callback: ((ScanResult) -> Void)?

    @ObservedObject private var keyboard = KeyboardResponder(defaultHeight: UIConstants.contentInset.bottom)
    @StateObject private var viewModel: AnyViewModel<QRCodeScannerState, QRCodeScannerInput>
    @State private var value: String = ""

    init(
        configuration: Configuration,
        blockchain: Blockchain,
        callback: ( (ScanResult) -> Void)? = nil
    ) {
        self.configuration = configuration
        let viewModel = AnyViewModel<QRCodeScannerState, QRCodeScannerInput>(QRCodeScannerViewModel(
            state: .init(blockchain: blockchain),
            secretStorage: SharedSecretStorageImpl()))
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.callback = callback
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson") { response in
                    switch response {
                    case .success(let result):
                        value = result.string
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                .frame(width: 300, height: 300)
                .cornerRadius(12)

                if configuration == .scannerAndInput {

                    Text("Or manual")
                    TextFieldView(
                        placeholder: "Enter value", blockchain: viewModel.state.blockchain,
                        allowQRScan: false,
                        value: value
                    ) { newValue in
                        value = newValue

                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                Spacer()
            }
            .padding(UIConstants.contentInset)
            .navigationBarColor()
            .padding(.bottom, keyboard.currentHeight)
            .animation(.easeOut(duration: 0.16))
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Scan QR code")
            .onChange(of: value) { newValue in
                viewModel.trigger(.parse(newValue))
            }
            .onChange(of: viewModel.state.state) { newState in
                switch newState {
                case .valid(let result):
                    callback?(result)
                default:
                    break
                }
            }
            .baseBackground()
        }
    }
}

struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView(
            configuration: .scannerAndInput,
            blockchain: .solana)

        QRCodeScannerView(
            configuration: .onlyScanner,
            blockchain: .solana)
    }
}
