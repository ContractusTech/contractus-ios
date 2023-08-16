import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let cardImage = Image(systemName: "creditcard")
    static let depositImage = Image(systemName: "arrow.down.to.line")
    static let loanImage = Image(systemName: "percent")
}

struct TopUpView: View {
    enum TopUpType {
        case crypto
        case loan
        case fiat(URL)
    }
    @StateObject var viewModel: AnyViewModel<TopUpViewModel.State, TopUpViewModel.Inputs> = .init(TopUpViewModel(accountService: try? APIServiceFactory.shared.makeAccountService()))
    
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
            case .error(_):
                break
            }
        }
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
                        .font(.caption.weight(.semibold))
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

final class TopUpViewModel: ViewModel {

    struct State: Equatable {
        enum State: Equatable {
            case none, loadingMethods, loaded(URL), error(String)
        }

        var state: State
        var disabled: Bool {
            switch state {
            case .loadingMethods:
                return true
            default: return false
            }
        }
    }

    enum Inputs {
        case getMethods
    }

    @Published private(set) var state: State

    private var accountService: ContractusAPI.AccountService?

    init(accountService: ContractusAPI.AccountService?) {
        self.accountService = accountService
        self.state = .init(state: .none)
    }

    func trigger(_ input: Inputs, after: AfterTrigger?) {
        switch input {
        case .getMethods:
            state.state = .loadingMethods
            accountService?.getTopUpMethods {[weak self] result in
                switch result {
                case .success(let data):
                    if let method = data.methods.first, let url = URL(string: method.url ?? "") {
                        self?.state.state = .loaded(url)
                    } else {
                        self?.state.state = .error(R.string.localizable.commonServiceUnavailable())
                    }

                case .failure(let error):
                    self?.state.state = .error(error.localizedDescription)
                }
            }
        }
    }
}

struct TopUpView_Previews: PreviewProvider {
    static var previews: some View {
        TopUpView { _ in

        }
    }
}
