//
//  CreateDealBondView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI
import ContractusAPI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
    static let checkmarkImage = Image(systemName: "checkmark")
}

struct CreateDealBondView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>

    @State var nextStep: Bool = false
    @State private var performanceBondType: PerformanceBondType?

    private let types: [PerformanceBondType] = [.none, .onlyClient, .onlyExecutor, .both]

    var body: some View {
        ZStack {
            NavigationLink(
                isActive: $nextStep,
                destination: {
                    CreateDealEncryptionView()
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

                VStack {
                    ForEach(types, id: \.self) { type in
                        Button {
                            ImpactGenerator.light()
                            performanceBondType = type
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(R.color.textBase.color)
                                        .multilineTextAlignment(.leading)
                                    Text(type.subtitle)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                        .foregroundColor(R.color.secondaryText.color)
                                        .multilineTextAlignment(.leading)
                                }
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
                .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)

                Spacer()
                
                Text(R.string.localizable.newDealAbleChangeHint())
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(R.color.secondaryText.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                CButton(
                    title: R.string.localizable.commonNext(),
                    style: .primary,
                    size: .large,
                    isLoading: false,
                    action: {
                        if let performanceBondType = performanceBondType {
                            viewModel.trigger(.setBondType(performanceBondType))
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
        return R.string.localizable.newDealTitle()
    }

    var stepTitle: String {
        return R.string.localizable.newDealBondTitle()
    }
    
    var stepSubtitle: String {
        return R.string.localizable.newDealBondSubtitle()
    }
}

#Preview {
    CreateDealBondView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
