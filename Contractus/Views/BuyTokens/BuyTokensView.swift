//
//  BuyTokensView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

import SwiftUI
import Combine

fileprivate enum Constants {
    static let closeImage = Image(systemName: "xmark")
}

struct BuyTokensView: View {
    enum SheetType: Identifiable {
        var id: String { "\(self)" }
        case payment(BuyTokensState.PaymentRequest)
    }

    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
        case successPayment
        case failPayment
    }

    @Environment(\.presentationMode) private var presentationMode

    @StateObject var viewModel: AnyViewModel<BuyTokensState, BuyTokensInput>
    @State var alertType: AlertType?
    @State var amountValue: String = "10000"
    @State var showContent: Bool = false
    @State var sheetType: SheetType? = nil
    @FocusState var amountFocused: Bool

    private let amountPublisher = PassthroughSubject<String, Never>()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showContent {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        TextField("", text: $amountValue)
                            .textFieldStyle(.plain)
                            .font(.largeTitle.weight(.medium))
                            .foregroundColor(viewModel.state.canNotBuy ? R.color.redText.color : R.color.textBase.color)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .focused($amountFocused)
                            .fixedSize(horizontal: amountValue.count < 12, vertical: false)
                            .onChange(of: amountValue) { newAmountValue in
                                if let amount = Double(newAmountValue.replacingOccurrences(of: ",", with: ".")) {
                                    viewModel.trigger(.setValue(amount))
                                } else {
                                    viewModel.trigger(.setValue(0))
                                }
                                amountPublisher.send(newAmountValue)
                            }
                            .onReceive(Just(amountValue)) { newValue in
                                var filtered = newValue.filter { "0123456789,.".contains($0) }
                                let components = filtered.replacingOccurrences(of: ",", with: ".").components(separatedBy: ".")
                                if let fraction = components.last, components.count > 1, fraction.count > 5 {
                                    filtered = String(filtered.dropLast())
                                }
                                if filtered != newValue {
                                    self.amountValue = filtered
                                }
                            }
                            .onReceive(
                                amountPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                            ) { newAmountValue in
                                viewModel.trigger(.calculate)
                            }
                            .padding(.leading, 12)

                        Text(R.string.localizable.buyTokenCtus())
                            .font(.largeTitle.weight(.medium))
                            .foregroundColor(R.color.secondaryText.color)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 6)
                            .padding(.trailing, 12)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .overlay(alignment: .bottom) {
                        BorderDivider(
                            color: R.color.baseSeparator.color,
                            width: 2
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 45)
                    .padding(.bottom, 16)

                    Text(R.string.localizable.buyTokenPrice(viewModel.state.price))
                        .font(.footnote.weight(.medium))
                        .foregroundColor(R.color.secondaryText.color)
                        .padding(.bottom, 8)
                }

                if viewModel.state.value < 10000 {
                    Text(R.string.localizable.buyTokenNotEnough((10000 - viewModel.state.value).clean))
                        .font(.footnote.weight(.medium))
                        .foregroundColor(R.color.secondaryText.color.opacity(0.5))
                }
                Spacer()

                HStack(alignment: .center) {
                    Text(R.string.localizable.commonPoweredBy())
                        .font(.footnote.weight(.medium))
                        .foregroundColor(R.color.secondaryText.color)

                    R.image.advcash.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 14)
                        .padding(.bottom, 2)

                }.padding()
                CButton(
                    title: R.string.localizable.buyTokenPayTitle(viewModel.state.pay),
                    style: .primary,
                    size: .large,
                    isLoading: viewModel.state.state == .loading,
                    isDisabled: viewModel.state.canNotBuy
                ) {
                    viewModel.trigger(.create)
                }
                .padding(.bottom, 16)
            }
            .fullScreenCover(item: $sheetType) { type in
                switch type {
                case .payment(let request):
                    NavigationView {
                        WebView(
                            request: request.asURLRequest(),
                            successUrl: request.successUrl,
                            failUrl: request.failUrl,
                            closeHandler: { isSuccess in
                                alertType = isSuccess ? .successPayment : .failPayment
                                sheetType = nil
                        })
                        .edgesIgnoringSafeArea(.bottom)
                        .navigationBarItems(
                            trailing: Button(R.string.localizable.commonClose(), action: {
                                sheetType = nil
                            })
                        )
                        .navigationTitle(R.string.localizable.commonPayment())
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .baseBackground()
                }
            }
            .padding(.horizontal, 18)
            .baseBackground()
            .navigationTitle(R.string.localizable.buyTokenTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)
                    }
                }
            }
            .onAppear {
                amountFocused = true
                // fix unexpected animation with navigation view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent.toggle()
                }
            }
            .onChange(of: viewModel.state.state) { state in
                switch state {
                case .openPayment(let request):
                    ImpactGenerator.success()
                    sheetType = .payment(request)
                case .openURL(let stringUrl):
                    guard let url = URL(string: stringUrl) else { return }
                    ImpactGenerator.success()
                    UIApplication.shared.open(url)
                default:
                    return
                }
            }
            .onChange(of: viewModel.state.errorState) { value in
                switch value {
                case .error(let errorMessage):
                    self.alertType = .error(errorMessage)
                case .none:
                    self.alertType = .none
                }
            }
            .alert(item: $alertType) { type in
                switch type {
                case .error(let message):
                    Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message),
                        dismissButton: .default(Text(R.string.localizable.commonOk())) {
                            viewModel.trigger(.resetError)
                        }
                    )
                case .successPayment:
                    Alert(
                        title: Text(R.string.localizable.buyTokenTitleSuccessPayment()),
                        message: Text(R.string.localizable.buyTokenTextSuccessPayment()),
                        dismissButton: .default(Text(R.string.localizable.commonOk())) {
                            viewModel.trigger(.resetError)
                        }
                    )
                case .failPayment:
                    Alert(
                        title: Text(R.string.localizable.buyTokenTitleErrorPayment()),
                        message: Text(R.string.localizable.buyTokenTextErrorPayment()),
                        dismissButton: .default(Text(R.string.localizable.commonOk())) {
                            viewModel.trigger(.resetError)
                        }
                    )
                }
            }
        }
    }
}

struct BuyTokensView_Previews: PreviewProvider {
    static var previews: some View {
        BuyTokensView(viewModel: AnyViewModel<BuyTokensState, BuyTokensInput>(
            BuyTokensViewModel(
                account: Mock.account,
                checkoutService: APIServiceFactory.shared.makeCheckoutService()
            )
        ))
    }
}
