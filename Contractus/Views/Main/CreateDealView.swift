//
//  CreateDealView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.09.2022.
//

import SwiftUI

fileprivate enum Constants {
    static let notSelectedImage = Image(systemName: "circle")
    static let selectedImage = Image(systemName: "circle.inset.filled")
    static let contractImage = Image(systemName: "doc.badge.plus")
    static let closeImage = Image(systemName: "xmark")
}

// MARK: - DealRoleView

struct DealRoleView: View {
    enum RoleType {
        case client, executor
    }

    let type: RoleType
    let isSelected: Bool
    var action: (RoleType) -> Void

    var body: some View {
        Button {
            action(type)
        } label: {
            HStack(alignment: .center) {
                if isSelected {
                    Constants.selectedImage
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(R.color.textBase.color)
                } else {
                    Constants.notSelectedImage
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(R.color.textBase.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(R.color.textBase.color)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.leading)
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 0))
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                
                    .stroke(isSelected ? R.color.textBase.color : R.color.baseSeparator.color, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(R.color.secondaryBackground.color)
                    ))



        }
    }

    var title: String {
        switch type {
        case .client:
            return R.string.localizable.newDealTitleClient()
        case .executor:
            return R.string.localizable.newDealTitleExecutor()
        }
    }

    var subtitle: String {
        switch type {
        case .client:
            return R.string.localizable.newDealSubtitleClient()
        case .executor:
            return R.string.localizable.newDealSubtitleExecutor()
        }
    }
}

// MARK: - CreateDealView

struct CreateDealView: View {

    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    var didCreated: (() -> Void)?

    @State private var selectedType: DealRoleView.RoleType?
    @State private var isShowShareSecretKey: Bool = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                NavigationLink(destination: LazyView(ShareContentView(
                    content:viewModel.state.shareable!,
                    title: "Share secret key",
                    subTitle: "The partner must scan the QR code in order to start working on the contract.",
                    copyAction: { _ in
                        
                    },
                    closeAction: {
                        presentationMode.wrappedValue.dismiss()
                    })
                ), isActive: $isShowShareSecretKey, label: { EmptyView() })
                VStack(spacing: 24) {
                    //                    Constants.contractImage
                    //                        .resizable()
                    //                        .aspectRatio(contentMode: .fit)
                    //                        .frame(width: 140, height: 140, alignment: .center)
                    VStack(spacing: 4) {
                        Text(R.string.localizable.newDealTitle())
                            .font(.footnote.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundColor(R.color.secondaryText.color)

                        Text(R.string.localizable.newDealSubtitle())
                            .font(.largeTitle.weight(.heavy))

                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                    VStack {
                        DealRoleView(type: .client, isSelected: selectedType == .client) { role in
                            selectedType = role
                        }
                        DealRoleView(type: .executor, isSelected: selectedType == .executor) { role in
                            selectedType = role
                        }
                        Spacer()
                    }.padding()
                }
                .onChange(of: viewModel.state.state) { newValue in
                    if newValue == .success {
                        didCreated?()
                        isShowShareSecretKey.toggle()
                    }
                }
                LargePrimaryLoadingButton(
                    action: {
                        viewModel.trigger(selectedType == .client ? .createDealAsClient : .createDealAsExecutor)
                    },
                    isLoading: viewModel.state.state == .creating) {
                        HStack {
                            Spacer()
                            Text(R.string.localizable.commonCreate())
                            Spacer()
                        }
                    }
                    .disabled(selectedType == nil)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
            }
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
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

        }
        .navigationBarBackButtonHidden()
    }
}

#if DEBUG

struct CreateDealView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDealView(viewModel: AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))


    }
}

#endif
