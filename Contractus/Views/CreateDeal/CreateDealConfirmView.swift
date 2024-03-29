//
//  CreateDealConfirmView.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 02.11.2023.
//

import SwiftUI

fileprivate enum Constants {
    static let backImage = Image(systemName: "chevron.left")
    static let closeImage = Image(systemName: "xmark")
    static let lockImage = Image(systemName: "lock.fill")
}

struct CreateDealConfirmItemView: View {
    var title: String
    var value: String
    var titleColor: Color = R.color.textBase.color

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(titleColor)
                .multilineTextAlignment(.leading)
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(R.color.secondaryText.color)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
}

struct CreateDealConfirmView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: AnyViewModel<CreateDealState, CreateDealInput>
    
    @State var nextStep: Bool = false
    
    var body: some View {
        ZStack {
           VStack(alignment: .center, spacing: 6) {
               ScrollView {
                   Text(stepTitle)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(R.color.textBase.color)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 26)

                   VStack(spacing: 0) {
                       CreateDealConfirmItemView(
                        title: viewModel.state.role == .client
                        ? R.string.localizable.newDealExecutorAccount()
                        : R.string.localizable.newDealClientAccount(),
                        value: viewModel.contractor.isEmpty ? R.string.localizable.commonEmpty() : ContentMask.mask(from: viewModel.contractor)
                       )
                       Divider()

                       if viewModel.checkType == .checker {
                           CreateDealConfirmItemView(
                            title: R.string.localizable.newDealCheckerAccount(),
                            value: viewModel.checker.isEmpty ? R.string.localizable.commonEmpty() : ContentMask.mask(from: viewModel.checker))
                           Divider()
                       }
                       
                       CreateDealConfirmItemView(
                        title: R.string.localizable.newDealConfirmDeadlineTitle(),
                        value: viewModel.state.deadline?.asDateFormatted() ?? ""
                       )
                   }
                   .background(R.color.secondaryBackground.color)
                   .cornerRadius(20)
                   .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
                   
                   HStack {
                       Text(R.string.localizable.commonImmutable())
                           .font(.footnote.weight(.semibold))
                           .textCase(.uppercase)
                           .foregroundColor(R.color.secondaryText.color)
                       Spacer()
                   }
                   .padding(.top, 24)
                   .padding(.bottom, 8)
                   VStack(spacing: 0) {
                       CreateDealConfirmItemView(
                        title: R.string.localizable.newDealConfirmRoleTitle(),
                        value: viewModel.state.role == .client
                        ? R.string.localizable.dealTextClient()
                        : R.string.localizable.dealTextExecutor(),
                        titleColor: R.color.secondaryText.color
                       )
                       
                       Divider()
                       
                       CreateDealConfirmItemView(
                        title: R.string.localizable.newDealConfirmEncryptionTitle(),
                        value: viewModel.state.encryption
                        ? R.string.localizable.commonOn()
                        : R.string.localizable.commonOff(),
                        titleColor: R.color.secondaryText.color
                       )
                       
                       Divider()
                       
                       CreateDealConfirmItemView(
                        title: R.string.localizable.newDealConfirmCheckerTitle(),
                        value: viewModel.state.checkType == .checker
                        ? R.string.localizable.commonYes()
                        : R.string.localizable.commonNo(),
                        titleColor: R.color.secondaryText.color
                       )
                       
                       if viewModel.state.checkType != .checker {
                           Divider()
                           
                           CreateDealConfirmItemView(
                            title: R.string.localizable.dealPerformanceBond(),
                            value: viewModel.state.bondType?.shortTitle ?? "",
                            titleColor: R.color.secondaryText.color
                           )
                       }
                   }
                   .background(R.color.secondaryBackground.color)
                   .cornerRadius(20)
                   .shadow(color: R.color.shadowColor.color, radius: 2, y: 1)
               }
               Spacer()
               
               CButton(title: R.string.localizable.commonCreate(), style: .primary, size: .large, isLoading: viewModel.state.state == .creating, action: {
                   EventService.shared.send(event: ExtendedAnalyticsEvent.newDealCreateTap(
                       viewModel.state.role!,
                       viewModel.state.checkType == .checker,
                       viewModel.state.bondType ?? .none,
                       viewModel.state.encryption
                   ))
                   viewModel.trigger(.createDeal)
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
        return R.string.localizable.newDealConfirmTitle()
    }
    
    var stepSubtitle: String {
        return R.string.localizable.newDealConfirmSubtitle()
    }
}

#Preview {
    CreateDealConfirmView()
        .environmentObject(AnyViewModel<CreateDealState, CreateDealInput>(CreateDealViewModel(account: Mock.account, accountAPIService: nil, dealsAPIService: nil)))
}
