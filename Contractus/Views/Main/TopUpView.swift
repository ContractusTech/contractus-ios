import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let cardImage = Image(systemName: "creditcard")
    static let depositImage = Image(systemName: "arrow.down.to.line")
    static let loanImage = Image(systemName: "percent")
}

struct TopUpView: View {
    enum AlertType {
        case error(String)
    }

    enum TopUpType {
        case crypto
        case loan
        case fiat(URL)
    }

    @StateObject var viewModel: AnyViewModel<TopUpViewModel.State, TopUpViewModel.Inputs> = .init(TopUpViewModel(accountService: try? APIServiceFactory.shared.makeAccountService()))
    
    @State private var alertType: AlertType?

    var action: (TopUpType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(R.string.localizable.commonTopUp())
                    .font(.title2)
            }
            .padding(.bottom, 6)
            .padding(.top, 6)
            itemView(image: Constants.depositImage, title: R.string.localizable.topupTitleCrypto(), description: R.string.localizable.topupSubtitleCrypto(), disabled: viewModel.state.disabled, loading: false) {
                action(.crypto)
            }

            itemView(image: Constants.cardImage, title: R.string.localizable.topupTitleCards(), description: R.string.localizable.topupSubtitleCards(), disabled: viewModel.state.disabled, loading: viewModel.state.state == .loadingMethods) {
                viewModel.trigger(.getMethods)

            }

            itemView(image: Constants.loanImage, title: R.string.localizable.topupTitleLoad(), description: R.string.localizable.topupSubtitleLoad(), disabled: true, loading: false) {
                action(.loan)
            }
            Spacer()
        }
        .padding(20)
        .onChange(of: viewModel.state.state) { newState in
            switch newState {
            case .loaded(let url):
                action(.fiat(url))
            case .none:
                break
            case .loadingMethods:
                break
            }
        }
        .onChange(of: viewModel.state.errorState) { value in
            switch value {
            case .error(let errorMessage):
                self.alertType = .error(errorMessage)
            case .none:
                self.alertType = nil
            }
        }
        .alert(item: $alertType, content: { type in
            switch type {
            case .error(let message):
                return Alert(
                    title: Text(R.string.localizable.commonError()),
                    message: Text(message),
                    dismissButton: .default(Text(R.string.localizable.commonOk())) {
                        viewModel.trigger(.hideError)
                    }
                )
            }
        })
    }

    @ViewBuilder
    func itemView(image: Image, title: String, description: String, disabled: Bool, loading: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(4)

                VStack(alignment: .leading, spacing: 6){
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(R.color.textBase.color)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(R.color.secondaryText.color)
                }
                Spacer()
                if loading {
                    ProgressView()
                }

            }
            .padding()
            .background(content: {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(R.color.baseSeparator.color, lineWidth: 1)
            })
            .opacity(disabled ? 0.6 : 1.0)
        }
        .disabled(disabled)

    }
}

extension TopUpView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        }
    }
}

struct TopUpView_Previews: PreviewProvider {
    static var previews: some View {
        TopUpView { _ in

        }
    }
}
