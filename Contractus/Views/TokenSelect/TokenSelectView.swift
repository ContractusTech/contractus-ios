import SwiftUI
import ContractusAPI
import NukeUI
import Nuke
import SVGKit
import Shimmer

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
    static let crownImage = Image(systemName: "crown.fill")
    static let closeImage = Image(systemName: "xmark")
}

struct TokenSelectView: View {

    enum ViewResult {
        case single(ContractusAPI.Token)
        case many([ContractusAPI.Token])
        case close
        case none
    }

    @StateObject var viewModel: AnyViewModel<TokenSelectViewModel.State, TokenSelectViewModel.Input>
    
    @State private var searchString: String = ""

    var action: (ViewResult) -> Void

    var body: some View {
        VStack {
            TextField(R.string.localizable.selectTokenSearch(), text: $searchString)
                .textFieldStyle(SearchTextFieldStyle())
                .padding(.horizontal, 14)
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.state.state == .loading {
                        ForEach(1...6, id: \.self) { _ in
                            tokenItem(token: Mock.tokenEmpty, loading: true)
                                .shimmering()
                        }
                    } else {
                        ForEach(viewModel.state.tokens, id: \.id) { token in
                            tokenItem(token: token)
                            if token != viewModel.state.tokens.last {
                                Divider().foregroundColor(R.color.buttonBorderSecondary.color)
                            }
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
            .padding(.bottom, 32)
        }
        .baseBackground()
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarItems(
            leading: Button {
                switch viewModel.state.mode {
                case .many:
                    action(.none)
                case .single:
                    if let token = viewModel.state.selectedTokens.first {
                        action(.single(token))
                    } else {
                        action(.none)
                    }
                case .select:
                    action(.close)
                }
            } label: {
                Constants.closeImage
                    .resizable()
                    .frame(width: 21, height: 21)
                    .foregroundColor(R.color.textBase.color)
            },
            trailing: Button {
                action(.many(viewModel.state.selectedTokens))
            } label: {
                if viewModel.mode == .many {
                    Text(R.string.localizable.commonSave())
                } else {
                    EmptyView()
                }
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

    var title: String {
        switch viewModel.mode {
        case .single, .select:
            return R.string.localizable.selectTokenTitle()
        case .many:
            return "\(R.string.localizable.selectTokenTitle()) (\(viewModel.state.selectedTokens.count))"
        }
    }

    @ViewBuilder
    func tokenItem(token: ContractusAPI.Token, loading: Bool = false) -> some View {
        HStack(spacing: 13) {
            if let logoURL = token.logoURL {
                if logoURL.absoluteString.hasSuffix(".svg") {
                    SVGImageView(
                        url: logoURL,
                        size: CGSize(width: 24, height: 24)
                    )
                    .frame(width: 24, height: 24)
                    .cornerRadius(8)
                } else {
                    LazyImage(url: logoURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(R.color.fourthBackground.color)
                                .frame(width: 24, height: 24)
                                .cornerRadius(8)
                        }
                    }
                    .pipeline(ImagePipeline(configuration: .withDataCache))
                }
            } else {
                Rectangle()
                    .fill(R.color.fourthBackground.color)
                    .frame(width: 24, height: 24)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let name = token.name {
                    HStack {
                        if loading {
                            Rectangle()
                                .fill(R.color.fourthBackground.color)
                                .frame(width: 100, height: 18)
                                .cornerRadius(8)
                        } else {
                            Text(name)
                                .font(.body)
                                .foregroundColor(R.color.textBase.color)
                        }
                        if token.holderMode && viewModel.mode != .select {
                            Constants.crownImage
                                .imageScale(.small)
                                .foregroundColor(R.color.secondaryText.color)
                        }
                    }
                }
                if loading {
                    Rectangle()
                        .fill(R.color.fourthBackground.color)
                        .frame(width: 200, height: 18)
                        .cornerRadius(8)
                } else {
                    if let price = viewModel.state.balances[token.code] {
                        Text(price)
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                    } else {
                        Text(token.code)
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                    }
                }

            }
            .padding(.vertical, 16)

            Spacer()

            if viewModel.mode != .select {
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
        }
        .contentShape(Rectangle())
        .padding(.leading, 19)
        .padding(.trailing, 25)
        .opacity(opacity(for: token))
        .onTapGesture {
            guard viewModel.state.allowHolderMode || !token.holderMode || (token.holderMode && viewModel.state.tier == .holder) else { return }

            if viewModel.state.isSelected(token) {
                if !viewModel.state.isDisableUnselect(token){
                    viewModel.trigger(.deselect(token))
                    ImpactGenerator.soft()
                }
            } else {
                viewModel.trigger(.select(token))
                ImpactGenerator.soft()
                if viewModel.state.mode == .single || viewModel.state.mode == .select, let token = viewModel.state.selectedTokens.first {
                    action(.single(token))
                }
            }

        }
    }

    func opacity(for token: ContractusAPI.Token) -> Double {
        if (!viewModel.state.allowHolderMode && (token.holderMode && viewModel.state.tier != .holder)) || viewModel.state.isDisableUnselect(token) {
            return 0.4
        }

        return 1.0
    }
    
}

struct TokenSelectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TokenSelectView(viewModel: .init(TokenSelectViewModel(allowHolderMode: false, mode: .select, tier: .holder, selectedTokens: [], disableUnselectTokens: [], balance: nil, resourcesAPIService: nil))) { _ in

            }
        }
    }
}
