//
//  CreateDealView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.09.2022.
//

import SwiftUI
import ContractusAPI

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
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(R.color.textBase.color)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(R.color.secondaryText.color)
                        .multilineTextAlignment(.leading)
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 0))
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                
                    .stroke(isSelected ? R.color.textBase.color : R.color.buttonBorderSecondary.color, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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

    enum AlertType {
        case error(String)
    }
    
    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    var didCreated: ((Deal?) -> Void)?

    @State private var selectedType: DealRoleView.RoleType?
    @State private var isShowShareSecretKey: Bool = false
    @State private var alertType: AlertType?

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                ScrollView {
                    NavigationLink(destination: LazyView(ShareContentView(
                        informationType: .success,
                        content: viewModel.state.shareable!,
                        topTitle: "Created",
                        title: "The secret key",
                        subTitle: "The partner need scan the QR code to start working on the contract.",
                        copyAction: { _ in

                        },
                        dismissAction: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    ), isActive: $isShowShareSecretKey, label: { EmptyView() })
                    .isDetailLink(false)
                    VStack {

                        TopTextBlockView(
                            informationType: .none,
                            headerText: R.string.localizable.newDealTitle(),
                            titleText: R.string.localizable.newDealSubtitle(),
                            subTitleText: nil)

//                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                        VStack(spacing: 12) {
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
                            didCreated?(viewModel.state.createdDeal)
                            isShowShareSecretKey.toggle()
                        }
                        if newValue == .error {
                            self.alertType = .error("Error creating deal")
                        }
                    }
                }

                CButton(title: R.string.localizable.commonCreate(), style: .primary, size: .large, isLoading: viewModel.state.state == .creating, isDisabled: selectedType == nil) {
                    viewModel.trigger(selectedType == .client ? .createDealAsClient : .createDealAsExecutor)
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 28, trailing: 16))
            }
            .alert(item: $alertType, content: { type in
                switch type {
                case .error(let message):
                    return Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message),
                        dismissButton: .default(Text("Ok"), action: {
                            viewModel.trigger(.hideError)
                        }))
                }
            })
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

extension CreateDealView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        }
    }
}

#if DEBUG

struct CreateDealView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDealView(viewModel: AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))


    }
}

#endif
