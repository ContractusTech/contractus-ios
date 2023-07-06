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
    static let checkmarkImage = Image(systemName: "checkmark")
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
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? R.color.accentColor.color : .clear, lineWidth: 1.4))
                .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)

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

    @State private var selectedRole: DealRoleView.RoleType?
    @State private var isShowShareSecretKey: Bool = false
    @State private var alertType: AlertType?
    @State private var performanceBondType: PerformanceBondType?
    @State private var allowChecker: Bool = false
    private let types: [PerformanceBondType] = [.none, .onlyClient, .onlyExecutor, .both]

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
                    VStack(spacing: 12) {
                        HStack {
                            Text(R.string.localizable.newDealSubtitle())
                                .font(.title3.weight(.semibold))

                            Spacer()
                        }
                        .padding(.top, 24)
                        HStack(alignment: .center, spacing: 8) {

                            DealRoleView(type: .client, isSelected: selectedRole == .client) { role in
                                selectedRole = role
                            }

                            DealRoleView(type: .executor, isSelected: selectedRole == .executor) { role in
                                selectedRole = role
                            }

                        }
                        VStack(spacing: 0) {

                            HStack {
                                Toggle(isOn: $allowChecker.animation(.linear(duration: 0.2))) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Check by third party")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text("The decision to complete the deal will be made by a third party. ")
                                            .font(.footnote)
                                            .foregroundColor(R.color.secondaryText.color)
                                    }
                                }
                            }
                            .padding(16)
                            .background(content: {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(R.color.baseSeparator.color)
                            })
                            if !allowChecker {
                                HStack {
                                    Text("Who will add the performance bond?")
                                        .font(.title3.weight(.semibold))

                                    Spacer()
                                }
                                .padding(.top, 24)
                                .padding(.bottom, 12)

                                VStack {
                                    ForEach(types, id: \.self) { type in
                                        Button {
                                            performanceBondType = type
                                        } label: {
                                            HStack {
                                                Text(type.title)
                                                Spacer()
                                                if performanceBondType == type {
                                                    ZStack {
                                                        Constants.checkmarkImage
                                                            .imageScale(.small)
                                                            .foregroundColor(R.color.buttonTextPrimary.color)
                                                    }
                                                    .frame(width: 24, height: 24)
                                                    .background(R.color.accentColor.color)
                                                    .cornerRadius(7)
                                                } else {
                                                    ZStack {}
                                                        .frame(width: 24,  height: 24)
                                                        .overlay(
                                                            RoundedRectangle(
                                                                cornerRadius: 7,
                                                                style: .continuous
                                                            )
                                                            .stroke(R.color.fourthBackground.color, lineWidth: 1)
                                                        )
                                                }
                                            }
                                            .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                                        }

                                        if types.last != type {
                                            Divider().foregroundColor(R.color.baseSeparator.color)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                                .background(R.color.secondaryBackground.color)
                                .cornerRadius(20)
                                .shadow(color: R.color.shadowColor.color.opacity(0.4), radius: 2, y: 1)
                            }

                        }
                    }
                    .padding(8)
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
                .safeAreaInset(edge: .bottom, content: {
                    CButton(title: R.string.localizable.commonCreate(), style: .primary, size: .large, isLoading: viewModel.state.state == .creating, isDisabled: !allowCreateDeal) {

                        guard let selectedRole = selectedRole else { return }
                        if allowChecker {
                            viewModel.trigger(.createDealWithChecker(selectedRole.role))
                            return
                        }

                        guard let performanceBondType = performanceBondType else { return }
                        viewModel.trigger(.createDeal(selectedRole.role, performanceBondType))
                    }
                    .padding(EdgeInsets(top: 16, leading: 8, bottom: 28, trailing: 8))
                })



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
            .navigationBarTitle(R.string.localizable.newDealTitle(), displayMode: .inline)

        }
        .navigationBarBackButtonHidden()
    }

    var allowCreateDeal: Bool {
        selectedRole != nil && (performanceBondType != nil || allowChecker)
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

extension PerformanceBondType {
    var title: String {
        switch self {
        case .none:
            return "Nobody"
        case .both:
            return "Both, client and executor"
        case .onlyClient:
            return "Only client"
        case .onlyExecutor:
            return "Only executor"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .none:
            return "Nobody"
        case .both:
            return "Both"
        case .onlyClient:
            return "Client"
        case .onlyExecutor:
            return "Executor"
        }
    }
}

fileprivate extension DealRoleView.RoleType {
    var role: OwnerRole {
        switch self {
        case .client:
            return .client
        case .executor:
            return .executor
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
