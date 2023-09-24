import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
    static let crownImage = Image(systemName: "crown.fill")
    static let closeImage = Image(systemName: "xmark")
}

struct TokenSelectView: View {

    enum ViewResult {
        case single(ContractusAPI.Token)
        case many([ContractusAPI.Token])
        case none
    }

    @StateObject var viewModel: AnyViewModel<TokenSelectViewModel.State, TokenSelectViewModel.Input>
    
    @State private var searchString: String = ""

    var action: (ViewResult) -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextField(R.string.localizable.selectTokenSearch(), text: $searchString)
                    .textFieldStyle(SearchTextFieldStyle())
                    .padding(.horizontal, 14)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.state.tokens, id: \.self) { token in
                            tokenItem(token: token)
                            if token != viewModel.state.tokens.last {
                                Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                            }
                        }
                    }
                    .background(
                        Color(R.color.secondaryBackground()!)
                            .clipped()
                            .cornerRadius(20)
                            .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                    )
                }
            }
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarItems(
                leading: Button {
                    switch viewModel.state.mode {
                    case .many:
                        action(.many(viewModel.state.selectedTokens))
                    case .single:
                        if let token = viewModel.state.selectedTokens.first {
                            action(.single(token))
                        } else {
                            action(.none)
                        }
                        
                    }
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: searchString, perform: { newText in
                viewModel.trigger(.search(newText))
            })
            .onAppear {
                viewModel.trigger(.load)
            }
        }
    }

    var title: String {
        if viewModel.mode == .single {
            return R.string.localizable.selectTokenTitle()
        }
        return "\(R.string.localizable.selectTokenTitle()) (\(viewModel.state.selectedTokens.count)"
    }

    @ViewBuilder
    func tokenItem(token: ContractusAPI.Token) -> some View {
        HStack(spacing: 13) {
            if let logoURL = token.logoURL {
                AsyncImage(url: logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(R.color.fourthBackground.color)
                        .frame(width: 24, height: 24)
                        .cornerRadius(8)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                if let name = token.name {
                    HStack {
                        Text(name)
                            .font(.body)
                            .foregroundColor(R.color.textBase.color)

                        if token.holderMode {
                            Constants.crownImage
                                .imageScale(.small)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                    }
                }
                Text(token.code)
                    .font(.footnote)
                    .foregroundColor(R.color.secondaryText.color)
            }
            .padding(.vertical, 16)

            Spacer()

            Group {
                if viewModel.state.isSelected(token) {
                    ZStack {
                        Constants.checkmarkImage
                            .imageScale(.small)
                            .foregroundColor(R.color.accentColor.color)
                    }
                    .frame(width: 24, height: 24)
                    .background(R.color.fourthBackground.color)
                    .cornerRadius(7)
                } else {
                    ZStack {}
                        .frame(width: 24,  height: 24)
                        .background(R.color.thirdBackground.color)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 7,
                                style: .continuous
                            )
                            .stroke(R.color.fourthBackground.color, lineWidth: 1)
                        )
                }
            }
            .contentShape(Rectangle())

        }
        .padding(.leading, 19)
        .padding(.trailing, 25)
        .opacity((viewModel.state.allowHolderMode || !token.holderMode || (token.holderMode && viewModel.state.tier == .holder)) ? 1.0 : 0.4)
        .onTapGesture {
            guard viewModel.state.allowHolderMode || !token.holderMode || (token.holderMode && viewModel.state.tier == .holder) else { return }

            if viewModel.state.isSelected(token) {
                viewModel.trigger(.deselect(token))
            } else {
                viewModel.trigger(.select(token))
                if viewModel.state.mode == .single, let token = viewModel.state.selectedTokens.first {
                    action(.single(token))
                }
            }

        }
    }
    
}

struct TokenSelectView_Previews: PreviewProvider {
    static var previews: some View {
        TokenSelectView(viewModel: .init(TokenSelectViewModel(allowHolderMode: false, mode: .many, tier: .holder, selectedTokens: [], resourcesAPIService: nil))) { _ in

        }
    }
}
