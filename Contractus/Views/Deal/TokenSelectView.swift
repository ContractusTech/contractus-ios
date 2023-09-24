//
//  TokenSelectView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 22.09.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let checkmarkImage = Image(systemName: "checkmark")
    static let crownImage = Image(systemName: "crown.fill")
    static let closeImage = Image(systemName: "xmark")
}

struct TokenSelectView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var searchString: String = ""
    var availableTokens: [ContractusAPI.Token]
    @Binding var selectedToken: ContractusAPI.Token
    var allowHolderMode: Bool

    var body: some View {
        NavigationView {
            VStack {
                TextField(R.string.localizable.selectTokenSearch(), text: $searchString)
                    .textFieldStyle(SearchTextFieldStyle())
                    .padding(.horizontal, 14)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(availableTokensFiltered(), id: \.self) { token in
                            tokenItem(token: token)
                            if token != availableTokens.last {
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
                    dismiss()
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            )
            .navigationTitle(R.string.localizable.selectTokenTitle())
            .navigationBarTitleDisplayMode(.inline)
        }
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
                    ProgressView()
                        .frame(width: 24, height: 24)
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
                                .foregroundColor(R.color.labelBackgroundDefault.color)
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
                if token.code == selectedToken.code {
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
                        .background(
                            !token.holderMode || (token.holderMode && allowHolderMode)
                            ? Color.clear
                            : R.color.thirdBackground.color.opacity(0.2)
                        )
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
            .onTapGesture {
                if !token.holderMode || (token.holderMode && allowHolderMode) {
                    selectedToken = token
                    dismiss()
                }
            }
        }
        .padding(.leading, 19)
        .padding(.trailing, 25)
    }
    
    func availableTokensFiltered() -> [ContractusAPI.Token] {
        if searchString.isEmpty {
            return availableTokens
        }
        return availableTokens.filter({
            ($0.name ?? "").uppercased().contains(searchString.uppercased()) ||
            $0.code.uppercased().contains(searchString.uppercased())
        })
    }
}

struct TokenSelectView_Previews: PreviewProvider {
    static var previews: some View {
        TokenSelectView(
            availableTokens: Mock.tokenList,
            selectedToken: .constant(Mock.tokenSOL),
            allowHolderMode: false
        )
    }
}
