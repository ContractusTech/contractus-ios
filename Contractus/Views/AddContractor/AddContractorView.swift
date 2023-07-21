//
//  AddContractorView.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.09.2022.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let contactIcon = Image(systemName: "person.fill.badge.plus")
    static let userImage = Image(systemName: "person.fill.badge.plus")
    static let closeImage = Image(systemName: "xmark")
}

struct AddContractorView: View {

    enum AlertType {
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode

    @State private var publicKey: String
    @State private var isActiveShareSecret = false
    @StateObject var viewModel: AnyViewModel<AddContractorState, AddContractorInput>
    var action: (Deal?) -> Void

    @State var alertType: AlertType?
    @State var isLoading: Bool = false

    init(
        viewModel: AnyViewModel<AddContractorState, AddContractorInput>,
        action: @escaping (Deal?) -> Void)
    {
        self._publicKey = State(wrappedValue: viewModel.state.publicKey)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.action = action
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                VStack(spacing: 12) {
                    switch viewModel.state.participateType {
                    case .contractor:
                        TopTextBlockView(
                            headerText: R.string.localizable.addContractorTitlePartner(),
                            titleText: R.string.localizable.addContractorTitleEnterKey(),
                            subTitleText: viewModel.state.ownerIsClient ? R.string.localizable.addContractorDescriptionExecutor() : R.string.localizable.addContractorDescriptionClient())
                    case .checker:
                        TopTextBlockView(
                            headerText: R.string.localizable.addContractorTitleChecker(),
                            titleText: R.string.localizable.addContractorTitleEnterKey(),
                            subTitleText: R.string.localizable.addContractorDescriptionChecker())
                    }

                }
                Spacer(minLength: 32)
                VStack(alignment: .center, spacing: 22) {

                    TextFieldView(
                        placeholder: R.string.localizable.commonPublicKey(), blockchain: viewModel.blockchain,
                        value: viewModel.state.publicKey
                    ) { newValue in
                            viewModel.trigger(.validate(newValue))
                        }
                    Text(R.string.localizable.addContractorTypeAccountInfo(viewModel.state.blockchain.rawValue))
                        .font(.callout)
                        .foregroundColor(R.color.secondaryText.color)
                    Spacer()
                }

                NavigationLink(
                    isActive: $isActiveShareSecret,
                    destination: {
                        ShareContentView(
                            content: viewModel.state.shareableData,
                            topTitle: nil,
                            title: R.string.localizable.shareTitleDefault(),
                            subTitle: R.string.localizable.shareSubtitleDefault()) { _ in
                                // TODO: - Copy
                            } dismissAction: {

                            }
                    },
                    label: { EmptyView() }
                )
                Spacer()
                if case let .invalidPublicKey(error) = viewModel.state.state {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(R.color.redText.color)
                        .multilineTextAlignment(.center)
                    CButton(
                        title: R.string.localizable.commonAdd(),
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.state.isLoading,
                        isDisabled: true
                    ) {
                        viewModel.trigger(.addContractor)
                    }
                } else {
                    CButton(
                        title: R.string.localizable.commonAdd(),
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.state.isLoading,
                        isDisabled: false
                    ) {
                        viewModel.trigger(.addContractor)
                    }
                }
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
            .navigationBarTitleDisplayMode(.inline)
            .baseBackground()
            .edgesIgnoringSafeArea(.bottom)
            .onChange(of: viewModel.state.state) { value in
                switch value {
                case .successAdded:
                    action(viewModel.state.deal)
                    presentationMode.wrappedValue.dismiss()
                default: break
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        action(nil)
                    } label: {
                        Constants.closeImage
                            .resizable()
                            .frame(width: 21, height: 21)
                            .foregroundColor(R.color.textBase.color)

                    }
                }
            }
            .alert(item: $alertType, content: { type in
                switch type {
                case .error(let message):
                    return Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message))
                }
            })

        }
    }

    var disableAddButton: Bool {
        switch viewModel.state.state {
        case .validPublicKey:
            return false
        default:
            return true
        }
    }

    var successTitle: String {
        switch viewModel.state.participateType {
        case .contractor:
            return  R.string.localizable.addContractorSuccessAddedPartner()
        case .checker:
            return R.string.localizable.addContractorSuccessAddedChecker()
        }
    }
}

extension AddContractorView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return "error"
        }
    }
}

#if DEBUG

struct AddContractorView_Previews: PreviewProvider {
    static var previews: some View {
        AddContractorView(viewModel: AnyViewModel<AddContractorState, AddContractorInput>(AddContractorViewModel(
            account: Mock.account,
            participateType: .contractor,
            deal: Mock.deal,
            sharedSecretBase64: "",
            blockchain: .solana,
            dealService: nil,
            publicKey: nil)
        )) { _ in

        }.previewDisplayName("Partner View")

        AddContractorView(viewModel: AnyViewModel<AddContractorState, AddContractorInput>(AddContractorViewModel(
            account: Mock.account,
            participateType: .checker,
            deal: Mock.deal,
            sharedSecretBase64: "",
            blockchain: .solana,
            dealService: nil,
            publicKey: nil)
        )) { _ in

        }
        .previewDisplayName("Checker View")

        ShareContentView(
            content: ShareableDeal(dealId: "", secretBase64: "", command: .shareDealSecret),
            topTitle: nil,
            title: "Share key",
            subTitle: "For edit and sign contract partner must have this data.") { _ in
                // TODO: - Copy
            } dismissAction: {

            }
            .previewDisplayName("Share View")
    }
}

#endif

