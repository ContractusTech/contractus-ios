//
//  CreateDealView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let notSelectedImage = Image(systemName: "circle")
    static let selectedImage = Image(systemName: "circle.inset.filled")
    static let contractImage = Image(systemName: "doc.badge.plus")
    static let closeImage = Image(systemName: "xmark")
    static let checkmarkImage = Image(systemName: "checkmark")
    static let backImage = Image(systemName: "chevron.left")
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
                HStack(alignment: .top) {
                    switch type {
                    case .client:
                        R.image.dealClient.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72)
                    case .executor:
                        R.image.dealExecutor.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(R.color.textBase.color)
                            .multilineTextAlignment(.leading)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(R.color.secondaryText.color)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(.leading, 11)
                .padding(.top, 27)
                .padding(.bottom, 21)
                .background(R.color.secondaryBackground.color)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? R.color.accentColor.color : .clear, lineWidth: 1.4)
                )
                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
            }

        }.onTapGesture {
            ImpactGenerator.light()
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

struct CreateDealView: View {
    enum AlertType {
        case error(String)
    }

    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    var didCreated: ((Deal?) -> Void)?
    @State private var isShowShareSecretKey: Bool = false
    @State private var alertType: AlertType?
    
    @State var nextStep: Bool = false
    @State private var selectedRole: DealRoleView.RoleType?
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: LazyView(ShareContentView(
                    informationType: .success,
                    content: viewModel.state.shareable!,
                    topTitle: R.string.localizable.newDealCreatedTopTitle(),
                    title: R.string.localizable.newDealCreatedTitle(),
                    subTitle: R.string.localizable.newDealCreatedSubTitle(),
                    copyAction: { _ in
                        
                    },
                    dismissAction: {
                        presentationMode.wrappedValue.dismiss()
                    })
                ), isActive: $isShowShareSecretKey, label: { EmptyView() })
                .isDetailLink(false)

                NavigationLink(
                    isActive: $nextStep,
                    destination: {
                        CreateDealContractorView()
                            .environmentObject(viewModel)
                    },
                    label: {
                        EmptyView()
                    }
                )
                
                VStack(alignment: .center, spacing: 6) {
                    
                    Text(stepTitle)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(R.color.textBase.color)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 26)
                    
                    DealRoleView(type: .client, isSelected: selectedRole == .client) { role in
                        selectedRole = role
                    }
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                    DealRoleView(type: .executor, isSelected: selectedRole == .executor) { role in
                        selectedRole = role
                    }
                    .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                    Spacer()
                    
                    Text("You will not be able to change your role\nafter you create a deal")
                        .font(.footnote)
                        .foregroundColor(R.color.textWarn.color)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    CButton(title: R.string.localizable.commonNext(), style: .primary, size: .large, isLoading: false, action: {
                        if let selectedRole = selectedRole {
                            viewModel.trigger(.setRole(selectedRole.role))
                            nextStep.toggle()
                        }
                    })
                    
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .baseBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .onChange(of: viewModel.state.state) { state in
                switch state {
                case .none, .creating:
                    break
                case .success:
                    didCreated?(viewModel.state.createdDeal)
                    if viewModel.state.createdDeal?.sharedKey != nil {
                        EventService.shared.send(event: DefaultAnalyticsEvent.newDealOpenSuccessWithSk)
                        isShowShareSecretKey.toggle()
                    } else {
                        viewModel.trigger(.close)
                    }
                case .error(let message):
                    self.alertType = .error(message)
                case .close:
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .alert(item: $alertType) { type in
                switch type {
                case .error(let message):
                    Alert(
                        title: Text(R.string.localizable.commonError()),
                        message: Text(message),
                        dismissButton: .default(Text(R.string.localizable.commonOk())) {
                            viewModel.trigger(.hideError)
                        }
                    )
                }
            }
        }
    }
    
    var title: String {
        return R.string.localizable.newDealTitle()
    }
    
    var stepTitle: String {
        return "Choose your role"
    }
}

extension CreateDealView.AlertType: Identifiable {
    var id: String {
        switch self {
        case .error:
            return R.string.localizable.commonError()
        }
    }
}

extension PerformanceBondType {
    var title: String {
        switch self {
        case .none:
            return R.string.localizable.newDealBondNobody()
        case .both:
            return R.string.localizable.newDealBondBoth()
        case .onlyClient:
            return R.string.localizable.newDealBondClient()
        case .onlyExecutor:
            return R.string.localizable.newDealBondExecutor()
        }
    }
    
    var subtitle: String {
        switch self {
        case .none:
            return R.string.localizable.newDealBondNobodyHint()
        case .both:
            return R.string.localizable.newDealBondBothHint()
        case .onlyClient:
            return R.string.localizable.newDealBondClientHint()
        case .onlyExecutor:
            return R.string.localizable.newDealBondExecutorHint()
        }
    }
    
    var shortTitle: String {
        switch self {
        case .none:
            return R.string.localizable.newDealBondShortNobody()
        case .both:
            return R.string.localizable.newDealBondShortBoth()
        case .onlyClient:
            return R.string.localizable.newDealBondShortClient()
        case .onlyExecutor:
            return R.string.localizable.newDealBondShortExecutor()
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

#Preview {
    CreateDealView(viewModel: AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
