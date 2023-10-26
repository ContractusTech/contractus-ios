import SwiftUI

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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showContent {
                    AmountFieldView(
                        amountValue: $amountValue, 
                        color: viewModel.state.canNotBuy ? R.color.redText.color : R.color.textBase.color,
                        currencyCode: R.string.localizable.buyTokenCtus(),
                        didChange: { value in
                            viewModel.trigger(.setValue(value))
                        },
                        didFinish: {
                            viewModel.trigger(.calculate)
                        }, filter: { value in
                            return value.filterAmount(decimals: 5)
                        }
                    )

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
//                amountFocused = true
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
