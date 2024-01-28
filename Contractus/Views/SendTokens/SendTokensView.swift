import SwiftUI

struct SendTokensView: View {
    enum AlertType: Identifiable {
        var id: String { "\(self)" }
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<SendTokensViewModel.State, SendTokensViewModel.Input>
    @State var nextStep: Bool = false
    @State private var showSign: Bool = false
    @State private var alertType: AlertType?

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    isActive: $nextStep,
                    destination: {
                        SelectRecipientView()
                        .environmentObject(viewModel)
                    },
                    label: {
                        EmptyView()
                    }
                )

                TokenSelectView(viewModel: .init(TokenSelectViewModel(
                    allowHolderMode: true,
                    mode: .select,
                    tier: .holder,
                    selectedTokens: [],
                    disableUnselectTokens: [],
                    balance: viewModel.state.balance,
                    resourcesAPIService: try? APIServiceFactory.shared.makeResourcesService())
                )) { result in
                    switch result {
                    case .single(let token):
                        viewModel.trigger(.selectToken(token))
                        nextStep.toggle()
                    case .close:
                        presentationMode.wrappedValue.dismiss()
                    case .none, .many:
                        break
                    }
                }
            }
            .sheet(isPresented: $showSign) {
                if let type = viewModel.transactionSignType {
                    TransactionSignView(account: viewModel.state.account, type: type) {

                    } closeAction: { afterSign in
                        if afterSign {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }.interactiveDismiss(canDismissSheet: false)
                } else {
                    EmptyView()
                }
            }
            .onChange(of: viewModel.transactionSignType) { type in
                showSign = type != nil
            }
            .onChange(of: viewModel.state.errorState) { errorState in
                switch errorState {
                case .error(let errorMessage):
                    self.alertType = .error(errorMessage)
                case .none:
                    self.alertType = nil
                }
            }
            .alert(item: $alertType) { type in
                switch type {
                case .error(let message):
                    Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message),
                        dismissButton: .default(Text(R.string.localizable.commonOk())) {
                            viewModel.trigger(.hideError)
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    SendTokensView(
        viewModel: .init(SendTokensViewModel(
            state: .init(account: Mock.account, currency: .USD),
            accountAPIService: nil,
            transactionsService: nil,
            accountService: AccountServiceImpl(storage: ServiceFactory.shared.makeAccountStorage())
        ))
    )
}
