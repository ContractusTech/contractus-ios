//
//  CreateDealContractorView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
}

struct CreateDealContractorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    @State private var contractorPublicKey: String?
    
    var body: some View {
        ZStack {
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    CreateDealAllowCheckerView()
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
                    .padding(.bottom, 6)
                                
                Text(stepSubtitle)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 26)
                                
                TextFieldView(
                    placeholder: R.string.localizable.commonPublicKey(),
                    blockchain: .solana,
                    value: viewModel.state.contractor,
                    changeValue: { newValue in
                        contractorPublicKey = newValue
                    }, onQRTap: {
//                        EventService.shared.send(event: DefaultAnalyticsEvent.dealContractorQrscannerTap)
                    }
                )
                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                Text("Must be account on the Solana blockchain")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .padding(.top, 6)

                Spacer()
                
                Text("You will be able to change after you create a deal")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                CButton(
                    title: (contractorPublicKey ?? "").isEmpty
                    ? R.string.localizable.commonSkip()
                    : R.string.localizable.commonNext(),
                    style: .primary,
                    size: .large,
                    isLoading: false,
                    action: {
                        if let contractorPublicKey = contractorPublicKey {
                            viewModel.trigger(.setContractor(contractorPublicKey))
                            nextStep.toggle()
                        } else {
                            nextStep.toggle()
                        }
                    }
                )
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Constants.backImage
                        .resizable()
                        .frame(width: 12, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.trigger(.close)
                } label: {
                    Constants.closeImage
                        .resizable()
                        .frame(width: 21, height: 21)
                        .foregroundColor(R.color.textBase.color)
                }
            }
        }
    }
    
    var title: String {
        return "New deal"
    }

    var stepTitle: String {
        return viewModel.state.role == .client
        ? "Executor account"
        : "Client account"
    }
    
    var stepSubtitle: String {
        return viewModel.state.role == .client
        ? "Provide a service or sell a product."
        : "Order a service or buy a product"
    }
}

#Preview {
    CreateDealContractorView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
