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
        HStack {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .center, spacing: 0) {
                    switch type {
                    case .client:
                        R.image.dealClient.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    case .executor:
                        R.image.dealExecutor.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                    HStack {
                        Spacer()
                        VStack(alignment: .center, spacing: 4) {

                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(R.color.textBase.color)
                                .multilineTextAlignment(.center)
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundColor(R.color.secondaryText.color)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }

                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? R.color.textBase.color : R.color.baseSeparator.color, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(R.color.secondaryBackground.color)
                        )
                )
                if isSelected {
                    Constants.selectedImage
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(R.color.textBase.color)
                        .offset(.init(width: -12, height: 12))
                } else {
                    Constants.notSelectedImage
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(R.color.textBase.color.opacity(0.3))
                        .offset(.init(width: -12, height: 12))
                }

            }

        }.onTapGesture {
            ImpactGenerator.soft()
            action(type)
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
                        HStack(alignment: .center, spacing: 8) {

                            DealRoleView(type: .client, isSelected: selectedType == .client) { role in
                                selectedType = role
                            }

                            DealRoleView(type: .executor, isSelected: selectedType == .executor) { role in
                                selectedType = role
                            }

                        }.padding(8)
                    }
                    .onChange(of: viewModel.state.state) { state in
                        switch state {
                        case .none, .creating:
                            break
                        case .success:
                            didCreated?(viewModel.state.createdDeal)
                            isShowShareSecretKey.toggle()
                        case .error(let message):
                            self.alertType = .error(message)
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
//            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))


    }
}

#endif
