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
    @State private var errorText: String = ""

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
            ZStack {
                R.color.mainBackground.color
                VStack(spacing: 12) {
                    if errorText.isEmpty {
                        CodeScannerView(codeTypes: [.qr], simulatedData: "Contractus") { response in
                            switch response {
                            case .success(let result):
                                viewModel.trigger(.parse(result.string))
                            case .failure(let error):
                                errorText = error.localizedDescription
                            }
                        }
                        .frame(width: 320, height: 320)
                        .cornerRadius(20)
                    } else {

                        ZStack(alignment: .center) {
                            R.color.thirdBackground.color
                            CButton(title: R.string.localizable.commonTryAgain(), style: .secondary, size: .default, isLoading: false) {
                                errorText = ""
                                viewModel.trigger(.clear)
                            }
                        }
                        .frame(width: 320, height: 320)
                        .cornerRadius(20)
                    }


                    if configuration == .scannerAndInput {
                        Text(R.string.localizable.qrScannerManual())
                            .font(.callout)
                            .foregroundColor(R.color.secondaryText.color)
                        TextFieldView(
                            placeholder: R.string.localizable.qrScannerPlaceholder(), blockchain: viewModel.state.blockchain,
                            allowQRScan: false,
                            value: value
                        ) { newValue in
                            value = newValue
                        }
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                    }
                    if !errorText.isEmpty {
                        Text(errorText)
                            .font(.callout)
                            .foregroundColor(R.color.redText.color)
                            .multilineTextAlignment(.center)
                            .padding(8)
                    }
                    Spacer()
                }
                .padding(UIConstants.contentInset)
                .padding(.bottom, keyboard.currentHeight)
                .animation(.easeOut(duration: 0.16), value: keyboard.currentHeight)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(R.string.localizable.qrScannerTitle())
                .onChange(of: value) { newValue in
                    guard !newValue.isEmpty else { return }
                    viewModel.trigger(.parse(newValue))
                }
                .onChange(of: viewModel.state.state) { newState in
                    self.errorText = ""
                    switch newState {
                    case .valid(let result):
                        callback?(result)
                    case .invalidData:
                        self.errorText = R.string.localizable.qrScannerError()
                    case .none:
                        break

                    }
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
